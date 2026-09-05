import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/models/catalog.dart';
import 'package:mobile/data/books_provider.dart';
import 'package:mobile/data/content_provider_error.dart';

export 'package:mobile/data/content_provider_error.dart';

/// A PC storefront price for a game, as found on CheapShark. Prices are in
/// USD (CheapShark does not localize currency).
class PcPriceInfo {
  const PcPriceInfo({
    required this.salePrice,
    required this.normalPrice,
    required this.onSale,
    required this.storeName,
  });
  final double salePrice;
  final double normalPrice;
  final bool onSale;
  final String storeName;
}

/// CheapShark's `/deals` response only carries a numeric `storeID`; the name
/// comes from its separate, rarely-changing `/stores` endpoint. Hardcoded
/// here (snapshot from that endpoint) rather than fetched, to avoid a second
/// request for every price lookup.
const _cheapSharkStores = <String, String>{
  '1': 'Steam',
  '2': 'GamersGate',
  '3': 'GreenManGaming',
  '4': 'Amazon',
  '5': 'GameStop',
  '6': 'Direct2Drive',
  '7': 'GOG',
  '8': 'Origin',
  '9': 'Get Games',
  '10': 'Shiny Loot',
  '11': 'Humble Store',
  '12': 'Desura',
  '13': 'Uplay',
  '14': 'IndieGameStand',
  '15': 'Fanatical',
  '16': 'Gamesrocket',
  '17': 'Games Republic',
  '18': 'SilaGames',
  '19': 'Playfield',
  '20': 'ImperialGames',
  '21': 'WinGameStore',
  '22': 'FunStockDigital',
  '23': 'GameBillet',
  '24': 'Voidu',
  '25': 'Epic Games Store',
  '26': 'Razer Game Store',
  '27': 'Gamesplanet',
  '28': 'Gamesload',
  '29': '2Game',
  '30': 'IndieGala',
  '31': 'Blizzard Shop',
  '32': 'AllYouPlay',
  '33': 'DLGamer',
  '34': 'Noctre',
  '35': 'DreamGame',
};

class ContentProviders {
  const ContentProviders({
    http.Client? client,
    String? rawgApiKey,
    String? booksApiKey,
    String? androidCertSha1,
    BooksProvider? booksProvider,
  }) : _client = client,
       _rawgKey = rawgApiKey ?? rawgKey,
       _booksKey = booksApiKey ?? googleBooksKey,
       _certSha1 = androidCertSha1 ?? _androidCertSha1,
       _booksProvider = booksProvider;
  final http.Client? _client;
  final String _rawgKey, _booksKey, _certSha1;
  final BooksProvider? _booksProvider;
  static const rawgKey = String.fromEnvironment('RAWG_API_KEY');
  static const googleBooksKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

  /// A key restricted to "Android apps" in Google Cloud Console is only
  /// accepted when the request identifies itself via these headers (normally
  /// added by Play Services; a plain `http` call must set them manually).
  /// Without a matching cert fingerprint Google returns 403
  /// API_KEY_ANDROID_APP_BLOCKED, which is otherwise indistinguishable from a
  /// genuinely revoked key. Empty ANDROID_CERT_SHA1 means an unrestricted key.
  /// The package name matches android/app/build.gradle's applicationId and,
  /// unlike the cert fingerprint, never varies per machine or signing config,
  /// so it is not sourced from an easily-left-blank --dart-define.
  static const _androidCertSha1 = String.fromEnvironment('ANDROID_CERT_SHA1');

  /// Providers are quota limited (Google Books allows ~1000 requests/day), and
  /// the home screen fans out one request per shelf on every mode switch.
  /// Successful responses are memoised so re-entering a mode, revisiting a
  /// category page or pulling to refresh does not burn the daily budget.
  static const _cacheTtl = Duration(minutes: 10);
  static const _cacheLimit = 64;
  static final _cache = <String, ({DateTime at, dynamic body})>{};
  static final _inFlight = <String, Future<dynamic>>{};
  static final _sharedClient = http.Client();

  /// Clears the memoised provider responses. Used by tests.
  static void resetCache() {
    _cache.clear();
    _inFlight.clear();
  }

  Future<List<ContentItem>> search(
    CultureMode mode,
    String query, {
    bool byAuthor = false,
  }) async {
    if (query.trim().isEmpty) return [];
    switch (mode) {
      case CultureMode.watch:
        return _tvmaze(query);
      case CultureMode.play:
        return _rawg(query);
      case CultureMode.read:
        return _books.search(query, byAuthor: byAuthor);
    }
  }

  Future<List<ContentItem>> popularGames() async {
    if (_rawgKey.isEmpty) {
      throw const ContentProviderError(
        'Oyun sağlayıcısı yapılandırılmamış (RAWG_API_KEY eksik).',
      );
    }
    final data = await _get(
      Uri.https('api.rawg.io', '/api/games', {
        'key': _rawgKey,
        'ordering': '-rating',
        'page_size': '20',
        'platforms': '4',
      }),
    );
    final results = (data['results'] as List)
        .whereType<Map<String, dynamic>>()
        // A high average based on only a handful of votes is not useful as a
        // discovery ranking. Keep the score real, but require a meaningful
        // sample size before showing a game in the popular shelf.
        .where((x) => (x['ratings_count'] as num? ?? 0) >= 20)
        .toList();
    return Future.wait(results.map(_gameItemWithDetails));
  }

  Future<ContentItem> _gameItemWithDetails(Map<String, dynamic> x) async {
    final id = x['id'];
    var description = x['description_raw'] as String? ?? '';
    if (description.isEmpty && id != null) {
      // A missing detail response must not make the whole shelf disappear.
      // The list item remains usable with an empty, honest description.
      try {
        final detail = await _get(
          Uri.https('api.rawg.io', '/api/games/$id', {'key': _rawgKey}),
        );
        description = detail['description_raw'] as String? ?? '';
      } on ContentProviderError {
        // Keep provider failures isolated to this item's optional metadata.
      }
    }
    return ContentItem(
      title: x['name'] as String? ?? '',
      kind: 'Oyun',
      meta: 'Puan ${(x['rating'] as num?)?.toStringAsFixed(1) ?? '-'}',
      dateLabel: x['released'] as String? ?? '',
      imageUrl: x['background_image'] as String? ?? '',
      rating: (x['rating'] as num?)?.toDouble() ?? 0,
      description: description,
      platforms: _platformNames(x),
      externalId: 'rawg:$id',
    );
  }

  List<String> _platformNames(Map<String, dynamic> x) =>
      (x['platforms'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((p) => (p['platform'] as Map?)?['name'] as String?)
          .whereType<String>()
          .toList();

  /// RAWG's "parent platform" grouping (PC=1, PlayStation=2, Xbox=3,
  /// Nintendo=7, mobile is iOS=4 + Android=8 combined) used to filter a
  /// genre shelf or category grid down to one platform family.
  static const platformFilters = <String, String>{
    'PC': '1',
    'PlayStation': '2',
    'Xbox': '3',
    'Nintendo': '7',
    'Mobil': '4,8',
  };

  Future<List<ContentItem>> discover(CultureMode mode) async {
    switch (mode) {
      case CultureMode.play:
        return popularGames();
      case CultureMode.watch:
        final data = await _get(
          Uri.https('api.tvmaze.com', '/shows', {'page': '0'}),
        );
        final shows = (data as List)
            .whereType<Map<String, dynamic>>()
            .take(20)
            .map(
              (x) => ContentItem(
                title: x['name'] as String? ?? '',
                kind: 'Dizi',
                meta: x['language'] as String? ?? '',
                dateLabel: x['premiered'] as String? ?? '',
                imageUrl:
                    (x['image'] as Map<String, dynamic>?)?['original']
                        as String? ??
                    '',
                rating:
                    ((x['rating'] as Map?)?['average'] as num?)?.toDouble() ??
                    0,
                description: (x['summary'] as String? ?? '').replaceAll(
                  RegExp(r'<[^>]*>'),
                  '',
                ),
                externalId: 'tvmaze:${x['id']}',
              ),
            )
            .where((x) => x.title.isNotEmpty)
            .toList();
        return shows;
      case CultureMode.read:
        // Distinct from the `subject:fiction` shelf so the featured card and
        // the first shelf do not show the same volumes.
        return _books.discover('roman');
    }
  }

  /// A fixed set of genre shelves can never cover everything; this is the
  /// "see everything" escape hatch, ranked by rating with no genre filter.
  Future<List<ContentItem>> browseAll(
    CultureMode mode, {
    String? platformId,
  }) async {
    switch (mode) {
      case CultureMode.watch:
        final shows = await _get(
          Uri.https('api.tvmaze.com', '/shows', {'page': '0'}),
        );
        final sorted =
            (shows as List).whereType<Map<String, dynamic>>().toList()..sort(
              (a, b) => ((b['rating'] as Map?)?['average'] as num? ?? 0)
                  .compareTo((a['rating'] as Map?)?['average'] as num? ?? 0),
            );
        return sorted
            .take(60)
            .map(
              (x) => ContentItem(
                title: x['name'] as String? ?? '',
                kind: 'Dizi',
                meta: x['language'] as String? ?? '',
                dateLabel: x['premiered'] as String? ?? '',
                imageUrl:
                    (x['image'] as Map<String, dynamic>?)?['original']
                        as String? ??
                    '',
                rating:
                    ((x['rating'] as Map?)?['average'] as num?)?.toDouble() ??
                    0,
                description: (x['summary'] as String? ?? '').replaceAll(
                  RegExp(r'<[^>]*>'),
                  '',
                ),
                externalId: 'tvmaze:${x['id']}',
              ),
            )
            .where((x) => x.title.isNotEmpty)
            .toList();
      case CultureMode.play:
        if (_rawgKey.isEmpty) {
          throw const ContentProviderError(
            'Oyun sağlayıcısı yapılandırılmamış (RAWG_API_KEY eksik).',
          );
        }
        final data = await _get(
          Uri.https('api.rawg.io', '/api/games', {
            'key': _rawgKey,
            'ordering': '-rating',
            'page_size': '40',
            'parent_platforms': ?platformId,
          }),
        );
        return (data['results'] as List)
            .whereType<Map<String, dynamic>>()
            .where((x) => (x['ratings_count'] as num? ?? 0) >= 20)
            .map(
              (x) => ContentItem(
                title: x['name'] as String? ?? '',
                kind: 'Oyun',
                meta:
                    'Puan ${(x['rating'] as num?)?.toStringAsFixed(1) ?? '-'}',
                dateLabel: x['released'] as String? ?? '',
                imageUrl: x['background_image'] as String? ?? '',
                rating: (x['rating'] as num?)?.toDouble() ?? 0,
                description: x['description_raw'] as String? ?? '',
                platforms: _platformNames(x),
                externalId: 'rawg:${x['id']}',
              ),
            )
            .where((x) => x.title.isNotEmpty)
            .toList();
      case CultureMode.read:
        return _books.discover('roman');
    }
  }

  Future<List<ContentItem>> discoverGenre(
    CultureMode mode,
    String genre, {
    String? platformId,
  }) async {
    if (mode == CultureMode.watch) {
      final shows = await _get(
        Uri.https('api.tvmaze.com', '/shows', {'page': '0'}),
      );
      final filtered = (shows as List)
          .whereType<Map<String, dynamic>>()
          .where(
            (x) => ((x['genres'] as List?) ?? []).any(
              (g) => g.toString().toLowerCase() == genre.toLowerCase(),
            ),
          )
          .toList();
      filtered.sort(
        (a, b) => ((b['rating'] as Map?)?['average'] as num? ?? 0).compareTo(
          (a['rating'] as Map?)?['average'] as num? ?? 0,
        ),
      );
      return filtered
          .take(15)
          .map(
            (x) => ContentItem(
              title: x['name'] as String? ?? '',
              kind: 'Dizi',
              meta: genre,
              dateLabel: x['premiered'] as String? ?? '',
              imageUrl:
                  (x['image'] as Map<String, dynamic>?)?['original']
                      as String? ??
                  '',
              rating:
                  ((x['rating'] as Map?)?['average'] as num?)?.toDouble() ?? 0,
              description: (x['summary'] as String? ?? '').replaceAll(
                RegExp(r'<[^>]*>'),
                '',
              ),
              externalId: 'tvmaze:${x['id']}',
            ),
          )
          .where((x) => x.title.isNotEmpty)
          .toList();
    }
    if (mode == CultureMode.play) {
      if (_rawgKey.isEmpty) {
        throw const ContentProviderError(
          'Oyun sağlayıcısı yapılandırılmamış (RAWG_API_KEY eksik).',
        );
      }
      final data = await _get(
        Uri.https('api.rawg.io', '/api/games', {
          'key': _rawgKey,
          'genres': genre.toLowerCase(),
          'ordering': '-rating',
          'page_size': '20',
          'parent_platforms': ?platformId,
        }),
      );
      final results = (data['results'] as List)
          .whereType<Map<String, dynamic>>()
          .where((x) => (x['ratings_count'] as num? ?? 0) >= 20)
          .toList();
      final items = await Future.wait(results.map(_gameItemWithDetails));
      return items.where((x) => x.title.isNotEmpty).toList();
    }
    if (mode == CultureMode.read) {
      final query = switch (genre.toLowerCase()) {
        'fiction' => 'subject:fiction',
        'science-fiction' => 'subject:"science fiction"',
        'self-help' => 'subject:"self-help"',
        'history' => 'subject:history',
        'classics' => 'subject:classics',
        _ => 'subject:${genre.replaceAll('-', ' ')}',
      };
      return _books.discover(query);
    }
    return [];
  }

  /// TVMaze's own artwork tops out at 210x295, which reads as blurry on a
  /// full-width detail header. The iTunes Search API is free and keyless and
  /// happens to index most TV shows with much larger cover art; its CDN also
  /// serves any resolution on request, so the default 100x100 thumbnail is
  /// upscaled by rewriting the URL. Only called for single, high-visibility
  /// spots (the featured card, the detail page) — never per shelf item, to
  /// keep this to one extra request rather than one per poster.
  Future<String?> higherResPoster(String title) async {
    if (title.isEmpty) return null;
    try {
      final data = await _get(
        Uri.https('itunes.apple.com', '/search', {
          'term': title,
          'media': 'tvShow',
          'entity': 'tvSeason',
          'limit': '1',
        }),
      );
      final results = (data['results'] as List? ?? [])
          .whereType<Map<String, dynamic>>();
      if (results.isEmpty) return null;
      final artwork = results.first['artworkUrl100'] as String?;
      if (artwork == null) return null;
      return artwork.replaceFirst('100x100bb', '1200x1200bb');
    } on ContentProviderError {
      return null;
    }
  }

  /// RAWG carries no pricing. CheapShark is free, keyless, and covers PC
  /// storefronts (Steam, GOG, Epic, …) only — there is no equivalent free
  /// source for console or mobile prices. It requires a descriptive
  /// User-Agent or it refuses the request outright. Matching is by title
  /// only (no RAWG/CheapShark id mapping exists), so this is a best-effort
  /// lookup: called for one item at a time (the detail page), never a shelf.
  Future<PcPriceInfo?> pcPrice(String title) async {
    if (title.isEmpty) return null;
    try {
      final data = await _get(
        Uri.https('www.cheapshark.com', '/api/1.0/deals', {
          'title': title,
          'pageSize': '1',
          'sortBy': 'Savings',
        }),
        headers: const {
          'User-Agent': 'CultureBox/1.0 (studioskrayirhan@gmail.com)',
        },
      );
      final deals = (data as List? ?? []).whereType<Map<String, dynamic>>();
      if (deals.isEmpty) return null;
      final deal = deals.first;
      final sale = double.tryParse(deal['salePrice']?.toString() ?? '');
      final normal = double.tryParse(deal['normalPrice']?.toString() ?? '');
      if (sale == null || normal == null) return null;
      return PcPriceInfo(
        salePrice: sale,
        normalPrice: normal,
        onSale: deal['isOnSale'] == '1',
        storeName:
            _cheapSharkStores[deal['storeID']?.toString()] ?? 'PC mağazası',
      );
    } on ContentProviderError {
      return null;
    }
  }

  Future<List<ContentItem>> _tvmaze(String q) async {
    final data = await _get(
      Uri.https('api.tvmaze.com', '/search/shows', {'q': q}),
    );
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map((entry) {
          final show = entry['show'] as Map<String, dynamic>? ?? {};
          final image = show['image'] as Map<String, dynamic>? ?? {};
          final premiered = show['premiered'] as String? ?? '';
          return ContentItem(
            title: show['name'] as String? ?? '',
            kind: 'Dizi',
            meta: show['language'] as String? ?? '',
            dateLabel: premiered,
            imageUrl:
                image['original'] as String? ??
                image['medium'] as String? ??
                '',
            rating:
                ((show['rating'] as Map?)?['average'] as num?)?.toDouble() ?? 0,
            description: (show['summary'] as String? ?? '').replaceAll(
              RegExp(r'<[^>]*>'),
              '',
            ),
            externalId: 'tvmaze:${show['id']}',
          );
        })
        .where((item) => item.title.isNotEmpty)
        .toList();
  }

  Future<List<ContentItem>> _rawg(String q) async {
    if (_rawgKey.isEmpty) {
      throw const ContentProviderError(
        'Oyun sağlayıcısı yapılandırılmamış (RAWG_API_KEY eksik).',
      );
    }
    final data = await _get(
      Uri.https('api.rawg.io', '/api/games', {
        'key': _rawgKey,
        'search': q,
        'page_size': '20',
      }),
    );
    return (data['results'] as List)
        .whereType<Map<String, dynamic>>()
        .map(
          (x) => ContentItem(
            title: x['name'] ?? '',
            kind: 'Oyun',
            meta: '',
            dateLabel: '',
            imageUrl: x['background_image'] ?? '',
            rating: (x['rating'] as num?)?.toDouble() ?? 0,
            description: x['description_raw'] as String? ?? '',
            platforms: _platformNames(x),
            externalId: 'rawg:${x['id']}',
          ),
        )
        .where((x) => x.title.isNotEmpty)
        .toList();
  }

  BooksProvider get _books =>
      _booksProvider ??
      GoogleBooksProvider(
        request: _get,
        apiKey: _booksKey,
        androidCertSha1: _certSha1,
      );

  Future<dynamic> _get(Uri uri, {Map<String, String>? headers}) async {
    final client = _client ?? _sharedClient;
    // Test clients and differently restricted keys must not share responses.
    final key = '${identityHashCode(client)}|$uri|$headers';
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.at) < _cacheTtl) {
      return cached.body;
    }

    final pending = _inFlight[key];
    if (pending != null) return pending;
    final request = _fetch(client, uri, headers);
    _inFlight[key] = request;
    try {
      final body = await request;
      if (_cache.length >= _cacheLimit) _cache.remove(_cache.keys.first);
      _cache[key] = (at: DateTime.now(), body: body);
      return body;
    } finally {
      if (identical(_inFlight[key], request)) _inFlight.remove(key);
    }
  }

  Future<dynamic> _fetch(
    http.Client client,
    Uri uri,
    Map<String, String>? headers,
  ) async {
    final http.Response response;
    try {
      response = await client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
    } on Exception {
      throw const ContentProviderError(
        'Bağlantı kurulamadı. İnternet bağlantını kontrol et.',
      );
    }

    if (response.statusCode != 200) {
      throw ContentProviderError(_statusMessage(response.statusCode));
    }

    final dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ContentProviderError(
        'İçerik kaynağından geçersiz yanıt alındı.',
      );
    }

    return body;
  }

  String _statusMessage(int status) => switch (status) {
    401 || 403 => 'Provider erişimi reddetti. API anahtarını doğrula.',
    429 => 'Günlük istek kotası doldu. Daha sonra tekrar dene.',
    >= 500 => 'Provider şu anda yanıt vermiyor. Daha sonra tekrar dene.',
    _ => 'Provider yanıtı başarısız: $status',
  };
}
