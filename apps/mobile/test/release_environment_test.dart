import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/release_environment.dart';

void main() {
  test('release environment reports missing names without values', () {
    expect(
      () => const ReleaseEnvironment(values: {}).validate(),
      throwsA(isA<ReleaseEnvironmentError>()),
    );
  });

  test('release environment accepts required values', () {
    const environment = ReleaseEnvironment(
      values: {
        'FIREBASE_PROJECT_ID': 'emulator-project',
        'RAWG_API_KEY': 'test',
        'GOOGLE_BOOKS_API_KEY': 'test',
      },
    );
    expect(environment.validate, returnsNormally);
  });
}
