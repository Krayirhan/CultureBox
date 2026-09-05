import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:mobile/data/local_database.dart';
import 'package:mobile/data/library_item_codec.dart';
import 'package:mobile/models/catalog.dart';

class LocalRepository {
  LocalRepository(this.database);
  final LocalDatabase database;

  Future<List<StoredLocalItem>> readItems() async =>
      (await database.allItems()).map(StoredLocalItem.fromRow).toList();

  Future<void> add(ContentItem item, {String status = 'queued'}) async {
    await database.insertItem(
      ItemsCompanion.insert(
        title: item.title,
        metadataJson: Value(jsonEncode(encodeLibraryItem(item))),
        kind: item.kind,
        meta: Value(item.meta),
        dateLabel: Value(item.dateLabel),
        imageUrl: Value(item.imageUrl),
        progress: Value(item.progress),
        progressLabel: Value(item.progressLabel),
        status: status,
      ),
    );
  }
}

class StoredLocalItem {
  const StoredLocalItem({required this.item, required this.status});
  final ContentItem item;
  final String status;

  factory StoredLocalItem.fromRow(Item row) =>
      StoredLocalItem(item: libraryItemFromRow(row), status: row.status);
}

String encodeLocalPayload(Map<String, Object?> value) => jsonEncode(value);
