import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Auth boundary. Firebase initialization is owned by the app bootstrap
/// and must be configured per environment; this class never contains secrets.
class FirebaseAuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  /// `initialize()` is a one-time process-wide call; the plugin itself
  /// tolerates being initialized more than once, but this avoids the
  /// redundant platform channel round trip on every sign-in attempt.
  static bool _googleSignInReady = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<UserCredential> register(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
    await credential.user?.reload();
    return credential;
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// The web OAuth client id required on Android is read from
  /// `google-services.json` automatically, so no identifiers are passed here.
  Future<UserCredential> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;
    if (!_googleSignInReady) {
      await googleSignIn.initialize();
      _googleSignInReady = true;
    }
    final account = await googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const GoogleSignInIdTokenMissingException();
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleSignInReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } on GoogleSignInException {
        // Firebase has already ended the app session. A provider cleanup error
        // must not leave the UI pretending that the user is still signed in.
      }
    }
  }
}

/// Thrown when Google returns an authenticated account without an ID token,
/// which `signInWithCredential` cannot use. Distinct from
/// [FirebaseAuthException] because it never reaches Firebase.
class GoogleSignInIdTokenMissingException implements Exception {
  const GoogleSignInIdTokenMissingException();
  @override
  String toString() => 'Google girişi bir kimlik jetonu döndürmedi.';
}

String authErrorMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'E-posta veya şifre hatalı.';
    case 'email-already-in-use':
      return 'Bu e-posta zaten kayıtlı.';
    case 'weak-password':
      return 'Daha güçlü bir şifre seç.';
    case 'network-request-failed':
      return 'Bağlantıyı kontrol edip tekrar dene.';
    default:
      return 'Giriş sırasında bir sorun oluştu.';
  }
}
