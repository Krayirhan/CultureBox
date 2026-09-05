import 'package:mobile/models/catalog.dart';
import 'package:mobile/data/content_provider_error.dart';

typedef ProviderRequest = Future<dynamic> Function(
  Uri uri, {
  Map<String, String>? headers,
});

/// Books remain behind an independent contract so changing vendors does not
/// change search, library entries, or the watch/play providers.
abstract interface class BooksProvider {
  Future<List<ContentItem>> search(String query, {bool byAuthor = false});
  Future<List<ContentItem>> discover(String query, {bool preferTurkish = true});
}

class GoogleBooksProvider implements BooksProvider {
  const GoogleBooksProvider({
    required this.request,
    required this.apiKey,
    this.androidCertSha1 = '',
  });
  final ProviderRequest request;
  final String apiKey, androidCertSha1;

  @override
  Future<List<ContentItem>> search(String query, {bool byAuthor = false}) =>
      discover(byAuthor ? 'inauthor:"$query"' : query, preferTurkish: false);

  @override
  Future<List<ContentItem>> discover(
    String query, {
    bool preferTurkish = true,
  }) async {
    if (apiKey.isEmpty) {
      throw const ContentProviderError(
        'Kitap sağlayıcısı yapılandırılmamış (GOOGLE_BOOKS_API_KEY eksik).',
      );
    }
    final data = await request(
      Uri.https('www.googleapis.com', '/books/v1/volumes', {
        'q': query,
        'key': apiKey,
        'maxResults': '20',
        'printType': 'books',
        'orderBy': 'relevance',
      }),
      headers: androidCertSha1.isEmpty
          ? null
          : {
              'X-Android-Package': 'com.krayirhanstudio.culturebox',
              'X-Android-Cert': androidCertSha1,
            },
    );
    final items = (data['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_bookItem)
        .where((x) => x.title.isNotEmpty)
        .toList();
    if (preferTurkish) {
      final turkish = items.where((x) => x.descriptionIsTurkish).toList();
      final rest = items.where((x) => !x.descriptionIsTurkish).toList();
      return [...turkish, ...rest];
    }
    return items;
  }

  ContentItem _bookItem(Map<String, dynamic> entry) {
    final volume = entry['volumeInfo'] as Map<String, dynamic>? ?? {};
    final authors =
        (volume['authors'] as List?)
            ?.map((author) => author.toString())
            .where((author) => author.isNotEmpty)
            .join(', ') ??
        '';
    final categories =
        (volume['categories'] as List?)
            ?.map((category) => category.toString())
            .where((category) => category.isNotEmpty)
            .join(' · ') ??
        '';
    final cover =
        (volume['imageLinks'] as Map<String, dynamic>?)?['thumbnail']
            as String? ??
        '';
    return ContentItem(
      title: volume['title'] as String? ?? '',
      kind: 'Kitap',
      meta: categories,
      creator: authors,
      dateLabel: volume['publishedDate'] as String? ?? '',
      publishedYear: volume['publishedDate'] as String? ?? '',
      pageCount: (volume['pageCount'] as num?)?.toInt() ?? 0,
      imageUrl: cover.replaceFirst('http://', 'https://'),
      rating: (volume['averageRating'] as num?)?.toDouble() ?? 0,
      description: (volume['description'] as String? ?? '').replaceAll(
        RegExp(r'<[^>]*>'),
        '',
      ),
      descriptionIsTurkish: volume['language'] == 'tr',
      previewUrl: (volume['previewLink'] as String? ?? '').replaceFirst(
        'http://',
        'https://',
      ),
      externalId: entry['id'] == null ? '' : 'googlebooks:${entry['id']}',
    );
  }
}
