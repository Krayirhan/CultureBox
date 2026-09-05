import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile/data/firestore_sync_repository.dart';
import 'package:mobile/data/library_item_codec.dart';
import 'package:mobile/data/local_database.dart';
import 'package:mobile/data/sync_engine.dart';
import 'package:mobile/models/catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LibraryStatus { queued, continuing, saved, done, dropped }

class StoredLibraryItem {
  const StoredLibraryItem({required this.item, required this.status});
  final ContentItem item;
  final LibraryStatus status;
  Map<String, Object?> toJson() => {
    ...encodeLibraryItem(item),
    'status': status.name,
  };
}

/// Drift owns both the visible library and the durable, account-scoped outbox.
class LibraryStore {
  LibraryStore({
    LocalDatabase? database,
    FirestoreSyncRepository? remote,
    String? Function()? currentUid,
  }) : _database = database ?? _defaultDatabase,
       _remoteOverride = remote,
       _currentUid = currentUid ?? _firebaseUid;

  static final LocalDatabase _defaultDatabase = LocalDatabase(
    openLocalDatabase(),
  );
  static final _migrations = Expando<Future<void>>();
  static final _syncs = Expando<Map<String, Future<bool>>>();
  final LocalDatabase _database;
  final FirestoreSyncRepository? _remoteOverride;
  final String? Function() _currentUid;

  static String? _firebaseUid() =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid;

  FirestoreSyncRepository get _remote =>
      _remoteOverride ?? FirestoreSyncRepository();

  Future<void> _ensureMigrated() => _migrations[_database] ??=
      _migrateLegacyPreferences().catchError((Object error, StackTrace stack) {
        _migrations[_database] = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<void> _migrateLegacyPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('library_items');
    await _database.transaction(() async {
      if (raw != null && (await _database.allItems()).isEmpty) {
        final values = jsonDecode(raw) as List<dynamic>;
        for (final value in values.whereType<Map<String, dynamic>>()) {
          await _database.insertItem(
            _companion(
              decodeLibraryItem(value),
              value['status'] as String? ?? LibraryStatus.queued.name,
              '',
            ),
          );
        }
      }
      // Upgrade legacy rows exactly once. Clean cloud snapshots must never be
      // enqueued on refresh: doing so overwrites edits made on another device.
      if (await _database.preference('library_outbox_v2') == null) {
        final queuedIds = <String>{};
        for (final operation in await _database.pendingOperations()) {
          final data = jsonDecode(operation.payload) as Map<String, dynamic>;
          if (data['itemId'] is String) queuedIds.add(data['itemId'] as String);
        }
        for (final row in await _database.allItems()) {
          if (!queuedIds.contains(_rowId(row))) {
            await _enqueue(
              'upsert',
              _rowId(row),
              '',
              data: {
                ...encodeLibraryItem(libraryItemFromRow(row)),
                'status': row.status,
              },
            );
          }
        }
        await _database.setPreference('library_outbox_v2', 'done');
      }
    });
    if (raw != null) await prefs.remove('library_items');
  }

  Future<List<StoredLibraryItem>> read() async {
    final owner = _currentUid() ?? '';
    await _ensureMigrated();
    return (await _database.allItems(ownerUid: owner))
        .map(
          (row) => StoredLibraryItem(
            item: libraryItemFromRow(row),
            status: LibraryStatus.values.firstWhere(
              (status) => status.name == row.status,
              orElse: () => LibraryStatus.queued,
            ),
          ),
        )
        .toList();
  }

  Future<void> add(
    ContentItem item, {
    LibraryStatus status = LibraryStatus.queued,
  }) async {
    final owner = _currentUid() ?? '';
    await _ensureMigrated();
    await _database.transaction(() async {
      for (final row in await _matchingRows(item, owner)) {
        // Replacing a legacy title-based identity also removes its old cloud
        // document, so upgrading metadata does not create a duplicate entry.
        if (_rowId(row) != _itemId(item)) {
          await _enqueue('delete', _rowId(row), owner);
        }
        await _database.deleteItem(row.id);
      }
      await _database.insertItem(_companion(item, status.name, owner));
      await _enqueue(
        'upsert',
        _itemId(item),
        owner,
        data: {...encodeLibraryItem(item), 'status': status.name},
      );
      await _bumpRevision(owner);
    });
    await _flushIfAuthenticated(owner);
  }

  Future<void> update(ContentItem item, {required LibraryStatus status}) =>
      add(item, status: status);

  Future<void> remove(ContentItem item) async {
    final owner = _currentUid() ?? '';
    await _ensureMigrated();
    await _database.transaction(() async {
      final rows = await _matchingRows(item, owner);
      for (final row in rows) {
        await _database.deleteItem(row.id);
      }
      for (final id
          in rows.isEmpty ? {_itemId(item)} : rows.map(_rowId).toSet()) {
        await _enqueue('delete', id, owner);
      }
      await _bumpRevision(owner);
    });
    await _flushIfAuthenticated(owner);
  }

  Future<List<Item>> _matchingRows(ContentItem item, String owner) async =>
      (await _database.allItems(ownerUid: owner)).where((row) {
        final existing = libraryItemFromRow(row);
        if (existing.kind != item.kind) return false;
        if (existing.externalId.isNotEmpty && item.externalId.isNotEmpty) {
          return existing.externalId == item.externalId;
        }
        return existing.title == item.title;
      }).toList();

  Future<void> _enqueue(
    String operation,
    String itemId,
    String owner, {
    Map<String, Object?> data = const {},
  }) => _database.enqueue(
    operation,
    jsonEncode({'itemId': itemId, 'payload': data}),
    ownerUid: owner,
  );

  Future<void> _flushIfAuthenticated(String owner) async {
    if (owner.isEmpty || _currentUid() != owner) return;
    try {
      await SyncEngine(_remote, database: _database).drain(owner);
    } catch (_) {
      // The local transaction is committed; offline writes remain retryable.
    }
  }

  /// Explicit sign-in adopts guest changes once; another account's rows and
  /// pending changes remain in their own scope, including across sign-out.
  Future<void> _adoptGuestLibrary(String uid) =>
      _database.transaction(() async {
        final guestItems = await _database.allItems();
        final guestOperations = await _database.pendingOperations();
        if (guestItems.isEmpty && guestOperations.isEmpty) return;
        await (_database.update(_database.items)
              ..where((t) => t.ownerUid.equals('')))
            .write(ItemsCompanion(ownerUid: Value(uid)));
        await (_database.update(_database.outboxOperations)
              ..where((t) => t.ownerUid.equals('')))
            .write(OutboxOperationsCompanion(ownerUid: Value(uid)));
        await _bumpRevision('');
        await _bumpRevision(uid);
      });

  Future<void> migrateGuestLibraryToCloud(String uid) async {
    await synchronizeWithCloud(uid);
  }

  Future<bool> synchronizeWithCloud(String uid) {
    if (uid.isEmpty || _currentUid() != uid) return Future.value(false);
    final running = _syncs[_database] ??= {};
    return running[uid] ??= _synchronize(uid).whenComplete(() {
      running.remove(uid);
    });
  }

  Future<bool> _synchronize(String uid) async {
    await _ensureMigrated();
    if (_currentUid() != uid) return false;
    await _adoptGuestLibrary(uid);
    try {
      await SyncEngine(_remote, database: _database).drain(uid);
      return await restoreFromCloud(uid);
    } catch (_) {
      // A failed upload or authoritative server read preserves the local list.
      return false;
    }
  }

  Future<bool> refreshFromCloud() async {
    final uid = _currentUid();
    return uid == null ? false : synchronizeWithCloud(uid);
  }

  /// The server snapshot is installed atomically only if no local mutation
  /// occurred while the network read was in flight. Never clear the outbox.
  Future<bool> restoreFromCloud(String uid) async {
    await _ensureMigrated();
    if (_currentUid() != uid ||
        (await _database.pendingOperations(ownerUid: uid)).isNotEmpty) {
      return false;
    }
    final revision = await _revision(uid);
    final remoteItems = await _remote.readItems(uid);
    final companions = remoteItems.map((data) {
      if (data['title'] is! String || data['kind'] is! String) {
        throw const FormatException('Invalid library item');
      }
      return _companion(
        decodeLibraryItem(data),
        data['status'] as String? ?? LibraryStatus.queued.name,
        uid,
        cloudId: data['id'] as String?,
      );
    }).toList();
    return _database.transaction(() async {
      if (_currentUid() != uid ||
          await _revision(uid) != revision ||
          (await _database.pendingOperations(ownerUid: uid)).isNotEmpty) {
        return false;
      }
      await _database.clearItems(ownerUid: uid);
      for (final companion in companions) {
        await _database.insertItem(companion);
      }
      return true;
    });
  }

  /// Explicitly clears only the current device's cache for the active account.
  /// Sign-out must not call this: it would discard that account's offline edits.
  Future<void> clear() async {
    final owner = _currentUid() ?? '';
    await _ensureMigrated();
    await _database.transaction(() async {
      await _database.clearItems(ownerUid: owner);
      await _database.clearOutbox(ownerUid: owner);
      await _bumpRevision(owner);
    });
  }

  Future<int> _revision(String owner) async =>
      int.tryParse(
        await _database.preference('library_revision:$owner') ?? '',
      ) ??
      0;

  Future<void> _bumpRevision(String owner) async => _database.setPreference(
    'library_revision:$owner',
    '${await _revision(owner) + 1}',
  );

  ItemsCompanion _companion(
    ContentItem item,
    String status,
    String owner, {
    String? cloudId,
  }) => ItemsCompanion.insert(
    ownerUid: Value(owner),
    metadataJson: Value(
      jsonEncode({
        ...encodeLibraryItem(item),
        '_cloudId': cloudId ?? _itemId(item),
      }),
    ),
    title: item.title,
    kind: item.kind,
    meta: Value(item.meta),
    dateLabel: Value(item.dateLabel),
    imageUrl: Value(item.imageUrl),
    progress: Value(item.progress),
    progressLabel: Value(item.progressLabel),
    status: status,
  );

  String _rowId(Item row) =>
      (jsonDecode(row.metadataJson) as Map<String, dynamic>)['_cloudId']
          as String? ??
      _itemId(libraryItemFromRow(row));

  String _itemId(ContentItem item) => base64Url.encode(
    utf8.encode(
      '${item.kind}:${item.externalId.isEmpty ? item.title : item.externalId}',
    ),
  );
}
