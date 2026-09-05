import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/data/username_store.dart';
import 'package:mobile/models/public_profile.dart';
import 'package:mobile/models/review.dart';

/// Read-only access to someone else's public profile: their handle, their
/// library diary (if they left it visible), and their reviews (likewise).
/// Never used for the signed-in user's own data — that stays on
/// [LibraryStore] and the local Drift cache, which is the actual sync
/// source of truth.
class PublicProfileStore {
  PublicProfileStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  Future<PublicProfile?> fetchByUsername(String username) async {
    final uid = await UsernameStore().uidFor(username);
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    return data == null ? null : PublicProfile.fromMap(uid, data);
  }

  /// Only succeeds when the owner left `library.visible` on — the security
  /// rules enforce this independently, so a hidden library returns empty
  /// (a permission-denied read) rather than throwing.
  Future<List<PublicLibraryEntry>> libraryFor(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('items')
          .get();
      return snapshot.docs
          .map((doc) => PublicLibraryEntry.fromMap(doc.data()))
          .toList();
    } on FirebaseException {
      return const [];
    }
  }

  /// Reviews live under `content/{contentId}/reviews/{uid}`; finding every
  /// review by one author requires a collection-group query across all
  /// `content/*/reviews` subcollections, filtered by `uid`.
  Future<List<Review>> reviewsFor(String uid) async {
    final snapshot = await _firestore
        .collectionGroup('reviews')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return Future.wait(
      snapshot.docs.map((doc) async {
        final data = Map<String, dynamic>.from(doc.data());
        final contentRef = doc.reference.parent.parent;
        if (contentRef == null) return Review.fromMap(doc.id, data);

        // Reviews created before content details were duplicated into the review
        // document still get a useful, tappable subject on a public profile.
        if ((data['contentTitle'] as String? ?? '').isEmpty) {
          final content = await contentRef.get();
          final contentData = content.data();
          data.addAll({
            'contentId': content.id,
            'contentTitle': contentData?['title'] ?? '',
            'contentKind': contentData?['kind'] ?? '',
            'contentImageUrl': contentData?['imageUrl'] ?? '',
          });
        }
        return Review.fromMap(doc.id, data);
      }),
    );
  }
}
