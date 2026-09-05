import 'dart:convert';

import 'package:mobile/data/firestore_sync_repository.dart';
import 'package:mobile/data/local_database.dart';

/// Deterministic retry boundary for the outbox. Persistence of operations is
/// supplied by Drift in Sprint 1; this class keeps retry policy independent of UI.
class SyncEngine {
  SyncEngine(this.remote, {this.database});
  static final _drains = Expando<Map<String, Future<int>>>();
  final FirestoreSyncRepository remote;
  final LocalDatabase? database;

  Future<void> apply(String uid, SyncOperation operation) async {
    if (operation.type == 'delete') {
      await remote.deleteItem(uid: uid, itemId: operation.itemId);
      return;
    }
    if (operation.type != 'upsert') {
      throw FormatException('Unknown sync operation: ${operation.type}');
    }
    await remote.upsertItem(
      uid: uid,
      itemId: operation.itemId,
      data: operation.payload,
    );
  }

  Future<int> drain(String uid, {int maxAttempts = 3}) {
    if (uid.isEmpty) throw ArgumentError.value(uid, 'uid');
    if (maxAttempts < 1) {
      throw ArgumentError.value(maxAttempts, 'maxAttempts');
    }
    final db = database;
    if (db == null) return Future.value(0);
    final running = _drains[db] ??= {};
    return running[uid] ??= _drain(db, uid, maxAttempts).whenComplete(() {
      running.remove(uid);
    });
  }

  Future<int> _drain(LocalDatabase db, String uid, int maxAttempts) async {
    var applied = 0;
    while (true) {
      final pending = await db.pendingOperations(ownerUid: uid);
      if (pending.isEmpty) return applied;
      for (final row in pending) {
        final decoded = Map<String, dynamic>.from(
          jsonDecode(row.payload) as Map,
        );
        final operation = SyncOperation(
          type: row.operation,
          itemId: decoded['itemId'] as String,
          payload: Map<String, Object?>.from(
            decoded['payload'] as Map? ?? const {},
          ),
        );
        Object? lastError;
        var success = false;
        for (var attempt = 0; attempt < maxAttempts; attempt++) {
          try {
            await apply(uid, operation);
            success = true;
            break;
          } catch (error) {
            lastError = error;
          }
        }
        if (!success) {
          throw StateError(
            'Sync operation failed after $maxAttempts attempts: $lastError',
          );
        }
        await db.removeOperation(row.id);
        applied++;
      }
    }
  }
}
