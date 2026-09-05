import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/models/catalog.dart';

class Review {
  const Review({
    required this.uid,
    required this.username,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.contentId = '',
    this.contentTitle = '',
    this.contentKind = '',
    this.contentImageUrl = '',
  });

  final String uid;
  final String username;
  final int rating;
  final String text;
  final DateTime? createdAt;
  final String contentId;
  final String contentTitle;
  final String contentKind;
  final String contentImageUrl;

  factory Review.fromMap(String uid, Map<String, dynamic> data) => Review(
    uid: uid,
    username: data['username'] as String? ?? 'kullanıcı',
    rating: (data['rating'] as num?)?.toInt() ?? 0,
    text: data['text'] as String? ?? '',
    createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    contentId: data['contentId'] as String? ?? '',
    contentTitle: data['contentTitle'] as String? ?? '',
    contentKind: data['contentKind'] as String? ?? '',
    contentImageUrl: data['contentImageUrl'] as String? ?? '',
  );
}

/// The community-driven counterpart to a provider's own rating (RAWG,
/// TVMaze, Google Books) — shown side by side as "CultureBox Puanı" so the
/// two are never confused for one another.
class ContentRatingSummary {
  const ContentRatingSummary({required this.average, required this.count});
  final double average;
  final int count;
}

extension ReviewContentItem on Review {
  ContentItem toContentItem() => ContentItem(
    title: contentTitle,
    kind: contentKind,
    meta: '',
    dateLabel: '',
    imageUrl: contentImageUrl,
    externalId: contentId,
  );
}
