import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/firebase_bootstrap.dart';

void main() {
  test(
    'Firebase stays disabled by default for local guest development',
    () async {
      expect(await FirebaseBootstrap.initialize(enabled: false), isFalse);
    },
  );
}
