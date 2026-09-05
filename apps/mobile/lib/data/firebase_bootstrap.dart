import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseBootstrapError implements Exception {
  const FirebaseBootstrapError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Initializes Firebase only when the build explicitly opts in. Local guest
/// development remains Firebase-free; release CI must provide platform config.
class FirebaseBootstrap {
  static Future<bool> initialize({
    bool enabled = const bool.fromEnvironment('CULTUREBOX_FIREBASE'),
  }) async {
    if (!enabled) return false;
    try {
      await Firebase.initializeApp();
      return true;
    } on FirebaseException catch (error) {
      throw FirebaseBootstrapError(
        'Firebase initialization failed: ${error.code}',
      );
    } catch (_) {
      throw const FirebaseBootstrapError(
        'Firebase configuration is missing for this build.',
      );
    }
  }

  static void useEmulators({String host = '127.0.0.1'}) {
    FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  }
}
