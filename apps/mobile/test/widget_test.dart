import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/data/content_providers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final providers = ContentProviders(
    client: MockClient(
      (_) async => http.Response('''[
      {"name":"Sample Show","language":"English","premiered":"2020-01-01",
      "image":{"original":"https://example.com/a.jpg"},"rating":{"average":8.1},
      "summary":"<p>Text</p>","genres":["Drama"]}
    ]''', 200),
    ),
  );

  testWidgets('homepage renders discovery without bundled demo content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      CultureBoxApp(
        initialOnboardingComplete: true,
        guestMode: true,
        providers: providers,
      ),
    );
    expect(find.text('İzle'), findsWidgets);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Sample Show'), findsWidgets);
  });

  testWidgets('bottom navigation opens Listem and Profil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      CultureBoxApp(
        initialOnboardingComplete: true,
        guestMode: true,
        providers: providers,
      ),
    );

    await tester.tap(find.text('Listem'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('İzleme listen  •  0 içerik'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets('onboarding starts with the welcome step', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CultureBoxApp());
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.text(
        'İzleyeceklerini, oynayacaklarını ve okuyacaklarını tek yerde topla.',
      ),
      findsOneWidget,
    );
    expect(find.text('Devam et'), findsOneWidget);
  });
}
