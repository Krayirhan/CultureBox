import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/models/public_profile.dart';

class UsernameError implements Exception {
  const UsernameError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Usernames are reserved in a top-level `usernames/{username}` collection
/// (not a field on `users/{uid}`) so a Firestore transaction can check-and-
/// claim one atomically — two people racing for the same name cannot both
/// win, which a plain field write on the user doc would not guarantee.
class UsernameStore {
  UsernameStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  static final _validPattern = RegExp(r'^[a-z0-9_]{3,20}$');

  String? validationError(String raw) {
    final username = normalize(raw);
    if (!_validPattern.hasMatch(username)) {
      return '3-20 karakter, yalnızca küçük harf, rakam ve alt çizgi kullan.';
    }
    return null;
  }

  String normalize(String raw) => raw.trim().toLowerCase();

  /// Claims [username] for [uid], failing if it is already taken. Also
  /// writes the public-facing profile fields onto `users/{uid}` in the same
  /// transaction so the two never disagree.
  Future<void> reserve({
    required String uid,
    required String username,
    required String displayName,
  }) async {
    final name = normalize(username);
    final error = validationError(name);
    if (error != null) throw UsernameError(error);

    final usernameRef = _firestore.collection('usernames').doc(name);
    final userRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(usernameRef);
      if (existing.exists) {
        throw const UsernameError('Bu kullanıcı adı zaten alınmış.');
      }
      tx.set(usernameRef, {'uid': uid});
      tx.set(userRef, {
        'username': name,
        'displayName': displayName,
        'library': {'visible': true},
        'reviews': {'visible': true},
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<bool> isAvailable(String username) async {
    final name = normalize(username);
    if (validationError(name) != null) return false;
    final doc = await _firestore.collection('usernames').doc(name).get();
    return !doc.exists;
  }

  Future<String?> usernameFor(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['username'] as String?;
  }

  /// Resolves a `@handle` to its owner's uid via the `usernames` claim
  /// record — the public profile page's entry point.
  Future<String?> uidFor(String username) async {
    final doc = await _firestore
        .collection('usernames')
        .doc(normalize(username))
        .get();
    return doc.data()?['uid'] as String?;
  }

  /// The signed-in user's own profile doc — used by Profile to render the
  /// visibility toggles, as distinct from [PublicProfileStore] which reads
  /// someone else's.
  Future<PublicProfile?> profileFor(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    return data == null ? null : PublicProfile.fromMap(uid, data);
  }

  Future<void> setVisibility({
    required String uid,
    bool? libraryVisible,
    bool? reviewsVisible,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      if (libraryVisible != null) 'library': {'visible': libraryVisible},
      if (reviewsVisible != null) 'reviews': {'visible': reviewsVisible},
    }, SetOptions(merge: true));
  }
}
