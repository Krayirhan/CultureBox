import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/models/review.dart';

/// The community layer's storage boundary: one aggregate doc per piece of
/// content (`content/{contentId}`) plus one review per user underneath it
/// (`content/{contentId}/reviews/{uid}`), keyed by [ContentItem.externalId]
/// so a game, show, or book aggregates reviews across every user that opened
/// it rather than per app-session copy.
class ReviewsStore {
  ReviewsStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _contentRef(String contentId) =>
      _firestore.collection('content').doc(contentId);

  Future<ContentRatingSummary> summaryFor(String contentId) async {
    final doc = await _contentRef(contentId).get();
    final data = doc.data();
    final count = (data?['reviewCount'] as num?)?.toInt() ?? 0;
    final sum = (data?['ratingSum'] as num?)?.toDouble() ?? 0;
    return ContentRatingSummary(
      average: count == 0 ? 0 : sum / count,
      count: count,
    );
  }

  Future<List<Review>> listFor(String contentId) async {
    final snapshot = await _contentRef(contentId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snapshot.docs
        .map((doc) => Review.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<Review?> myReview(String contentId, String uid) async {
    final doc = await _contentRef(contentId)
        .collection('reviews')
        .doc(uid)
        .get();
    final data = doc.data();
    return data == null ? null : Review.fromMap(uid, data);
  }

  /// Writes (or edits) the caller's review and keeps `content/{contentId}`'s
  /// aggregate consistent in the same transaction — editing an existing
  /// review adjusts the running sum by the rating delta instead of counting
  /// it as a second review.
  Future<void> submit({
    required String contentId,
    required String kind,
    required String title,
    required String imageUrl,
    required String uid,
    required String username,
    required int rating,
    required String text,
  }) async {
    final contentRef = _contentRef(contentId);
    final reviewRef = contentRef.collection('reviews').doc(uid);

    await _firestore.runTransaction((tx) async {
      final contentSnap = await tx.get(contentRef);
      final existingReview = await tx.get(reviewRef);
      final previousRating = existingReview.data()?['rating'] as num?;

      final currentCount = (contentSnap.data()?['reviewCount'] as num?) ?? 0;
      final currentSum = (contentSnap.data()?['ratingSum'] as num?) ?? 0;
      final newCount = previousRating == null ? currentCount + 1 : currentCount;
      final newSum = previousRating == null
          ? currentSum + rating
          : currentSum - previousRating + rating;

      tx.set(contentRef, {
        'title': title,
        'kind': kind,
        'imageUrl': imageUrl,
        'reviewCount': newCount,
        'ratingSum': newSum,
      }, SetOptions(merge: true));

      tx.set(reviewRef, {
        'uid': uid,
        'username': username,
        // A denormalized content snapshot lets an author's public profile
        // render a review with its subject without a fan-out read per card.
        'contentId': contentId,
        'contentTitle': title,
        'contentKind': kind,
        'contentImageUrl': imageUrl,
        'rating': rating,
        'text': text,
        'createdAt':
            existingReview.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
