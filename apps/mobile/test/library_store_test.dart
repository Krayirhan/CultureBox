import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/library_store.dart';
import 'package:mobile/data/local_database.dart';
import 'package:mobile/models/catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalDatabase database;
  late String? activeUid;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = LocalDatabase(NativeDatabase.memory());
    activeUid = null;
  });

  tearDown(() => database.close());

  LibraryStore store() =>
      LibraryStore(database: database, currentUid: () => activeUid);

  const book = ContentItem(
    title: 'Kayıp Zamanın İzinde',
    kind: 'Kitap',
    meta: 'Roman',
    dateLabel: '1913',
    imageUrl: 'https://example.com/cover.jpg',
    rating: 4.7,
    description: 'Tam açıklama',
    creator: 'Marcel Proust',
    pageCount: 421,
    publishedYear: '1913',
    descriptionIsTurkish: true,
    previewUrl: 'https://books.example/preview',
    externalId: 'googlebooks:proust-1',
  );

  test(
    'round-trips all provider metadata and queues a durable mutation',
    () async {
      await store().add(book, status: LibraryStatus.saved);

      final saved = (await store().read()).single;
      expect(saved.status, LibraryStatus.saved);
      expect(saved.item.creator, book.creator);
      expect(saved.item.pageCount, book.pageCount);
      expect(saved.item.previewUrl, book.previewUrl);
      expect(saved.item.externalId, book.externalId);
      expect(await database.pendingOperations(), hasLength(1));
    },
  );

  test('keeps guest and signed-in account libraries isolated', () async {
    await store().add(book);
    activeUid = 'alice';
    await store().add(
      const ContentItem(
        title: 'Account item',
        kind: 'Film',
        meta: '',
        dateLabel: '',
        imageUrl: '',
        externalId: 'tvmaze:1',
      ),
    );

    expect((await store().read()).single.item.title, 'Account item');
    activeUid = null;
    expect((await store().read()).single.item.title, book.title);
    activeUid = 'alice';
    expect((await store().read()).single.item.title, 'Account item');
  });
}
