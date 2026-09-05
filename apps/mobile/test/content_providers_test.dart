import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/content_providers.dart';
import 'package:mobile/models/catalog.dart';

const _tvmazeShows = '''
[{"name":"Sample","language":"English","premiered":"2020-01-01",
  "image":{"original":"https://example.com/a.jpg"},
  "rating":{"average":8.1},"summary":"<p>Text</p>","genres":["Action"]}]
''';

const _books = '''
{"items":[
  {"volumeInfo":{"title":"English Book","language":"en","authors":["A"],
    "categories":["Fiction"],"pageCount":100,"publishedDate":"2001",
    "imageLinks":{"thumbnail":"http://books.google.com/x.jpg"}}},
  {"volumeInfo":{"title":"Türkçe Kitap","language":"tr","authors":["B"],
    "categories":["Kurgu"],"pageCount":200,"publishedDate":"2002",
    "imageLinks":{"thumbnail":"http://books.google.com/y.jpg"}}}
]}
''';

void main() {
  setUp(ContentProviders.resetCache);
  tearDown(ContentProviders.resetCache);

  test('discover parses watch results without an API key', () async {
    final providers = ContentProviders(
      client: MockClient((_) async => http.Response(_tvmazeShows, 200)),
    );
    final items = await providers.discover(CultureMode.watch);
    expect(items.single.title, 'Sample');
    expect(items.single.description, 'Text', reason: 'HTML must be stripped');
  });

  test('successful responses are memoised so quotas are not burned', () async {
    var calls = 0;
    final providers = ContentProviders(
      client: MockClient((_) async {
        calls++;
        return http.Response(_tvmazeShows, 200);
      }),
    );
    await providers.discover(CultureMode.watch);
    await providers.discover(CultureMode.watch);
    // Both calls resolve from the same cached provider response.
    expect(calls, 1);
  });

  test('quota and server failures surface actionable messages', () async {
    final quota = ContentProviders(
      client: MockClient((_) async => http.Response('{}', 429)),
    );
    await expectLater(
      quota.discover(CultureMode.watch),
      throwsA(
        isA<ContentProviderError>().having(
          (e) => e.message,
          'message',
          contains('kota'),
        ),
      ),
    );

    ContentProviders.resetCache();
    final offline = ContentProviders(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      offline.discover(CultureMode.watch),
      throwsA(
        isA<ContentProviderError>().having(
          (e) => e.message,
          'message',
          contains('Bağlantı'),
        ),
      ),
    );
  });

  test('an unparseable payload does not leak a raw FormatException', () async {
    final providers = ContentProviders(
      client: MockClient((_) async => http.Response('not json', 200)),
    );
    await expectLater(
      providers.discover(CultureMode.watch),
      throwsA(isA<ContentProviderError>()),
    );
  });

  group('read mode', () {
    test('reports a configuration error when the key is missing', () async {
      final providers = ContentProviders(
        client: MockClient((_) async => http.Response(_books, 200)),
      );
      await expectLater(
        providers.discover(CultureMode.read),
        throwsA(
          isA<ContentProviderError>().having(
            (e) => e.message,
            'message',
            contains('GOOGLE_BOOKS_API_KEY'),
          ),
        ),
      );
    });

    test('genre shelves query Google Books without langRestrict', () async {
      final requested = <Uri>[];
      final providers = ContentProviders(
        booksApiKey: 'test-books-key',
        client: MockClient((request) async {
          requested.add(request.url);
          return http.Response.bytes(utf8.encode(_books), 200);
        }),
      );

      final items = await providers.discoverGenre(
        CultureMode.read,
        'science-fiction',
      );

      expect(
        requested.single.queryParameters.containsKey('langRestrict'),
        isFalse,
        reason: 'English subject tags return nothing under langRestrict=tr',
      );
      expect(
        requested.single.queryParameters['q'],
        'subject:"science fiction"',
      );
      expect(items.map((x) => x.title), [
        'Türkçe Kitap',
        'English Book',
      ], reason: 'Turkish volumes are preferred by ordering, not by filtering');
      expect(items.first.kind, 'Kitap');
      expect(items.first.creator, 'B');
      expect(items.first.imageUrl, startsWith('https://'));
    });

    test('search does not reorder results by language', () async {
      final providers = ContentProviders(
        booksApiKey: 'test-books-key',
        client: MockClient(
          (_) async => http.Response.bytes(utf8.encode(_books), 200),
        ),
      );
      final items = await providers.search(CultureMode.read, 'kitap');
      expect(items.map((x) => x.title), ['English Book', 'Türkçe Kitap']);
    });
  });
}
