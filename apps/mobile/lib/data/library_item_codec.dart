import 'dart:convert';

import 'package:mobile/data/local_database.dart';
import 'package:mobile/models/catalog.dart';

/// The same shape is used by local metadata, cloud sync, and data export.
Map<String, Object?> encodeLibraryItem(ContentItem item) => {
  'title': item.title,
  'kind': item.kind,
  'meta': item.meta,
  'dateLabel': item.dateLabel,
  'imageUrl': item.imageUrl,
  'progress': item.progress,
  'progressLabel': item.progressLabel,
  'rating': item.rating,
  'description': item.description,
  'creator': item.creator,
  'pageCount': item.pageCount,
  'publishedYear': item.publishedYear,
  'descriptionIsTurkish': item.descriptionIsTurkish,
  'platforms': item.platforms,
  'previewUrl': item.previewUrl,
  'externalId': item.externalId,
};

ContentItem decodeLibraryItem(Map<String, dynamic> data) => ContentItem(
  title: data['title'] as String? ?? '',
  kind: data['kind'] as String? ?? '',
  meta: data['meta'] as String? ?? '',
  dateLabel: data['dateLabel'] as String? ?? '',
  imageUrl: data['imageUrl'] as String? ?? '',
  progress: (data['progress'] as num?)?.toDouble() ?? 0,
  progressLabel: data['progressLabel'] as String? ?? '',
  rating: (data['rating'] as num?)?.toDouble() ?? 0,
  description: data['description'] as String? ?? '',
  creator: data['creator'] as String? ?? '',
  pageCount: (data['pageCount'] as num?)?.toInt() ?? 0,
  publishedYear: data['publishedYear'] as String? ?? '',
  descriptionIsTurkish: data['descriptionIsTurkish'] as bool? ?? false,
  platforms: (data['platforms'] as List?)?.whereType<String>().toList() ?? [],
  previewUrl: data['previewUrl'] as String? ?? '',
  externalId: data['externalId'] as String? ?? '',
);

ContentItem libraryItemFromRow(Item row) => decodeLibraryItem({
  ...Map<String, dynamic>.from(jsonDecode(row.metadataJson) as Map),
  'title': row.title,
  'kind': row.kind,
  'meta': row.meta,
  'dateLabel': row.dateLabel,
  'imageUrl': row.imageUrl,
  'progress': row.progress,
  'progressLabel': row.progressLabel,
});
