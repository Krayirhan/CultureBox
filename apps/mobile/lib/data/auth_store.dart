import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile/data/firebase_auth_repository.dart';
import 'package:mobile/data/library_store.dart';
import 'package:mobile/data/username_store.dart';

class AuthStore {
  static const _emailKey = 'auth_email';
  String? lastError;

  Future<bool> signIn(String email, String password) async {
    lastError = null;
    if (!_valid(email, password)) {
      lastError = 'Geçerli bir e-posta ve en az 6 karakterli şifre gir.';
      return false;
    }
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuthRepository().signIn(email, password);
        final uid = FirebaseAuthRepository().currentUser?.uid;
        if (uid != null) await LibraryStore().synchronizeWithCloud(uid);
        return true;
      } on FirebaseAuthException catch (error) {
        lastError = authErrorMessage(error);
        return false;
      }
    }
    lastError = 'Hesap girişi bu derlemede kullanılamıyor. Misafir olarak devam edebilirsin.';
    return false;
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String username,
  ) async {
    lastError = null;
    if (!_valid(email, password)) {
      lastError = 'Geçerli bir e-posta ve en az 6 karakterli şifre gir.';
      return false;
    }
    final usernameError = UsernameStore().validationError(username);
    if (usernameError != null) {
      lastError = usernameError;
      return false;
    }
    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuthRepository().register(email, password, name);
        final uid = FirebaseAuthRepository().currentUser?.uid;
        if (uid != null) {
          // The account already exists at this point; a taken username is
          // recoverable (the user can set one later from Profile) and must
          // not be treated as a failed registration.
          try {
            await UsernameStore().reserve(
              uid: uid,
              username: username,
              displayName: name,
            );
          } on UsernameError catch (error) {
            lastError = error.message;
          }
          await LibraryStore().migrateGuestLibraryToCloud(uid);
        }
        return true;
      } on FirebaseAuthException catch (error) {
        lastError = authErrorMessage(error);
        return false;
      }
    }
    return signIn(email, password);
  }

  /// Requires the Google sign-in provider to be enabled server-side
  /// (Firebase Console > Authentication) and, on Android, the app's signing
  /// certificate SHA-1 registered against this Firebase project — otherwise
  /// Google returns a configuration error rather than the account picker.
  Future<bool> signInWithGoogle() async {
    lastError = null;
    if (Firebase.apps.isEmpty) {
      lastError = 'Google ile giriş bu derlemede kullanılamıyor.';
      return false;
    }
    try {
      final credential = await FirebaseAuthRepository().signInWithGoogle();
      final uid = credential.user?.uid;
      final isNewUser = credential.additionalUserInfo?.isNewUser ?? false;
      if (uid != null) {
        if (isNewUser) {
          await _claimAutoUsername(uid, credential.user?.displayName ?? '');
          await LibraryStore().migrateGuestLibraryToCloud(uid);
        } else {
          await LibraryStore().synchronizeWithCloud(uid);
        }
      }
      return true;
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled) {
        lastError = 'Google ile giriş yapılamadı. Tekrar dene.';
      }
      return false;
    } on FirebaseAuthException catch (error) {
      lastError = authErrorMessage(error);
      return false;
    } on GoogleSignInIdTokenMissingException catch (error) {
      lastError = error.toString();
      return false;
    }
  }

  /// Google sign-in collects no username, but every account needs one for
  /// the community layer (reviews, public profile) to work. A slug is
  /// derived from the Google display name and a numeric suffix is appended
  /// on collision — silent by design, since interrupting a first sign-in
  /// with a username picker would be a worse first impression than letting
  /// the user rename it later from Profile.
  Future<void> _claimAutoUsername(String uid, String displayName) async {
    final store = UsernameStore();
    final base = store
        .normalize(displayName)
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .padRight(3, '0');
    final slug = base.length > 16 ? base.substring(0, 16) : base;
    for (var attempt = 0; attempt < 5; attempt++) {
      final candidate = attempt == 0 ? slug : '$slug${attempt + 1}';
      try {
        await store.reserve(
          uid: uid,
          username: candidate,
          displayName: displayName,
        );
        return;
      } on UsernameError {
        // Taken or invalid after suffixing; try the next candidate.
      }
    }
    // Every candidate collided (extremely unlikely); the user can still set
    // one manually from Profile, so this is not treated as a sign-in failure.
  }

  /// Lets a signed-in user set or change their username from Profile —
  /// the recovery path for a registration whose chosen name lost a race, or
  /// for a Google account's auto-generated slug.
  Future<bool> setUsername(String username) async {
    lastError = null;
    if (Firebase.apps.isEmpty) {
      lastError = 'Bu işlem için giriş yapmalısın.';
      return false;
    }
    final uid = FirebaseAuthRepository().currentUser?.uid;
    if (uid == null) {
      lastError = 'Bu işlem için giriş yapmalısın.';
      return false;
    }
    try {
      await UsernameStore().reserve(
        uid: uid,
        username: username,
        displayName: FirebaseAuthRepository().currentUser?.displayName ?? '',
      );
      return true;
    } on UsernameError catch (error) {
      lastError = error.message;
      return false;
    }
  }

  Future<String?> currentEmail() async {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseAuthRepository().currentUser?.email;
    }
    return null;
  }

  Future<String?> currentUsername() async {
    if (Firebase.apps.isEmpty) return null;
    final uid = FirebaseAuthRepository().currentUser?.uid;
    if (uid == null) return null;
    return UsernameStore().usernameFor(uid);
  }

  /// Backfills a community handle for accounts created before usernames were
  /// introduced. The email local-part is the least surprising default; a
  /// numeric suffix handles collisions without blocking the profile screen.
  Future<String?> ensureUsernameForCurrentUser({String? email}) async {
    if (Firebase.apps.isEmpty) return null;
    final uid = FirebaseAuthRepository().currentUser?.uid;
    if (uid == null) return null;
    final existing = await UsernameStore().usernameFor(uid);
    if (existing != null && existing.isNotEmpty) return existing;

    final source = (email ?? await currentEmail() ?? 'user').split('@').first;
    final base = source
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final safeBase = (base.length < 3 ? '${base}user' : base).substring(
      0,
      (base.length < 3 ? '${base}user' : base).length.clamp(3, 16),
    );
    final store = UsernameStore();
    for (var attempt = 0; attempt < 100; attempt++) {
      final suffix = attempt == 0 ? '' : '${attempt + 1}';
      final candidate = '$safeBase$suffix';
      try {
        await store.reserve(
          uid: uid,
          username: candidate,
          displayName:
              FirebaseAuthRepository().currentUser?.displayName ?? source,
        );
        return candidate;
      } on UsernameError {
        // Try the next deterministic suffix when the local-part is taken.
      }
    }
    return null;
  }

  Future<String?> currentDisplayName() async {
    if (Firebase.apps.isNotEmpty) {
      return FirebaseAuthRepository().currentUser?.displayName;
    }
    return null;
  }

  Future<void> signOut() async {
    if (Firebase.apps.isNotEmpty) {
      await FirebaseAuthRepository().signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.setBool('guest_mode', false);
    // Account-scoped Drift rows remain private and retain pending offline work.
  }

  bool _valid(String email, String password) =>
      email.trim().contains('@') &&
      email.trim().contains('.') &&
      password.length >= 6;
}
