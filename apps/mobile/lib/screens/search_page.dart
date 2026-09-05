import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/data/auth_store.dart';
import 'package:mobile/data/firebase_auth_repository.dart';
import 'package:mobile/data/library_store.dart';
import 'package:mobile/data/reviews_store.dart';
import 'package:mobile/models/catalog.dart';
import 'package:mobile/models/review.dart';
import 'package:mobile/screens/auth_page.dart';
import 'package:mobile/screens/public_profile_page.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/widgets/cover_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile/data/content_providers.dart';
import 'package:mobile/data/on_device_translation_service.dart';
import 'package:mobile/data/recent_searches_store.dart';
import 'package:url_launcher/url_launcher.dart';

/// TVMaze has no trailer data, and there is no free, keyless trailer API, so
/// this opens a YouTube search instead of playing a trailer in-app.
Future<void> _openTrailerSearch(String title) async {
  final uri = Uri.https('www.youtube.com', '/results', {
    'search_query': '$title fragman',
  });
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.mode,
    this.providers = const ContentProviders(),
  });
  final CultureMode mode;
  final ContentProviders providers;
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _recentSearches = RecentSearchesStore();
  String _query = '';
  List<ContentItem> _remoteResults = [];
  String? _providerError;
  bool _searching = false;
  bool _byAuthor = false;
  List<String> _recent = const [];
  Timer? _debounce;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final mode = widget.mode;
    final value = await _recentSearches.read(mode.name);
    if (mounted && widget.mode == mode) setState(() => _recent = value);
  }

  @override
  void didUpdateWidget(covariant SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _debounce?.cancel();
      _request++;
      _controller.clear();
      _query = '';
      _remoteResults = [];
      _providerError = null;
      _searching = false;
      _byAuthor = false;
      _recent = const [];
      _loadRecent();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _request++;
    setState(() {
      _query = value;
      _remoteResults = [];
      _providerError = null;
      _searching = value.trim().isNotEmpty;
    });
    if (value.trim().isEmpty) return;
    // Waits for a pause in typing rather than searching on every keystroke —
    // cheap for local filtering, but the remote providers are quota-limited.
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _runSearch(value),
    );
  }

  Future<void> _runSearch(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    _debounce?.cancel();
    final request = ++_request;
    final mode = widget.mode;
    setState(() {
      _query = value;
      _searching = true;
      _providerError = null;
      _remoteResults = [];
    });
    try {
      final found = await widget.providers.search(
        mode,
        query,
        byAuthor: _byAuthor,
      );
      if (!mounted || request != _request) return;
      final kinds = switch (mode) {
        CultureMode.watch => const {'Film', 'Dizi'},
        CultureMode.play => const {'Oyun'},
        CultureMode.read => const {'Kitap'},
      };
      final unique = <String, ContentItem>{};
      for (final item in found.where((item) => kinds.contains(item.kind))) {
        unique.putIfAbsent(
          item.externalId.isEmpty
              ? '${item.kind}:${item.title}'
              : item.externalId,
          () => item,
        );
      }
      setState(() => _remoteResults = unique.values.toList());
      await _recentSearches.add(mode.name, query);
      if (mounted && request == _request) await _loadRecent();
    } on ContentProviderError catch (e) {
      if (mounted && request == _request) {
        setState(() => _providerError = e.message);
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _providerError = 'Arama yapılamadı. Tekrar dene.');
      }
    } finally {
      if (mounted && request == _request) setState(() => _searching = false);
    }
  }

  void _searchFor(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    setState(() => _query = value);
    _runSearch(value);
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final results = q.isEmpty ? <ContentItem>[] : _remoteResults;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          onSubmitted: _runSearch,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: widget.mode == CultureMode.read && _byAuthor
                ? 'Yazar adı ara'
                : modeCatalog[widget.mode]!.searchHint,
            border: InputBorder.none,
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Aramayı temizle',
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (widget.mode == CultureMode.read)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Başlık')),
                    ButtonSegment(value: true, label: Text('Yazar')),
                  ],
                  selected: {_byAuthor},
                  onSelectionChanged: (selected) {
                    setState(() => _byAuthor = selected.first);
                    if (_query.trim().isNotEmpty) _runSearch(_query);
                  },
                ),
              ),
            ),
          Expanded(
            child: q.isEmpty
                ? _RecentSearches(
                    queries: _recent,
                    onTap: _searchFor,
                    onClear: () async {
                      await _recentSearches.clear(widget.mode.name);
                      if (mounted) setState(() => _recent = const []);
                    },
                  )
                : _searching
                ? const Center(child: CircularProgressIndicator())
                : _providerError != null
                ? _Empty(
                    title: 'Arama kullanılamıyor',
                    message: _providerError!,
                    icon: Icons.cloud_off_rounded,
                    onRetry: () => _runSearch(_query),
                  )
                : results.isEmpty
                ? const _Empty(
                    title: 'Sonuç bulunamadı',
                    message: 'Başka bir başlık veya anahtar kelime dene.',
                    icon: Icons.search_off_rounded,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ResultRow(item: results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.queries,
    required this.onTap,
    required this.onClear,
  });
  final List<String> queries;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (queries.isEmpty) {
      return const _Empty(
        title: 'Aramaya başla',
        message: 'Sonuçlar seçili kategorinin dışına çıkmaz.',
        icon: Icons.search_rounded,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Son aramalar',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              TextButton(onPressed: onClear, child: const Text('Temizle')),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in queries)
                ActionChip(label: Text(q), onPressed: () => onTap(q)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.item});
  final ContentItem item;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => ContentDetailPage(item: item)),
    ),
    child: Ink(
      height: 92,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 92,
            child: CoverImage(url: item.imageUrl),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.kind}${_resultMeta(item).isEmpty ? '' : '  •  ${_resultMeta(item)}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          const SizedBox(width: 12),
        ],
      ),
    ),
  );
}

class ContentDetailPage extends StatelessWidget {
  const ContentDetailPage({super.key, required this.item});
  final ContentItem item;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      title: const Text('İçerik detayı'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(height: 260, child: SharpCoverImage(item: item)),
        ),
        const SizedBox(height: 20),
        Text(
          item.title,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 34,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${item.kind}${item.meta.isEmpty ? '' : '  •  ${item.meta}'}',
          style: const TextStyle(color: AppColors.muted),
        ),
        if (item.kind == 'Kitap' && item.creator.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.creator,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (item.kind == 'Kitap' &&
            (item.publishedYear.isNotEmpty || item.pageCount > 0)) ...[
          const SizedBox(height: 12),
          _BookFacts(item: item),
        ],
        if (item.rating > 0) ...[
          const SizedBox(height: 10),
          Text(
            'Puan ${item.rating.toStringAsFixed(1)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
        if (item.kind == 'Oyun' && item.platforms.contains('PC')) ...[
          const SizedBox(height: 12),
          _PcPriceBadge(title: item.title),
        ],
        _ContentSummary(item: item),
        if (item.externalId.isNotEmpty) ...[
          const SizedBox(height: 24),
          _CommunitySection(item: item),
        ],
        if (item.kind == 'Dizi' || item.kind == 'Film') ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _openTrailerSearch(item.title),
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: const Text('Fragman izle'),
          ),
        ],
        if (item.kind == 'Kitap' && item.previewUrl.isNotEmpty) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(item.previewUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Örnek oku'),
          ),
        ],
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => SharePreviewPage(item: item),
            ),
          ),
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Paylaş'),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () async {
            await LibraryStore().add(item);
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Listene eklendi.')));
            }
          },
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('Listeme ekle'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandAction,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    ),
  );
}

/// The community layer: CultureBox's own aggregate rating (distinct from the
/// provider's own "Puan"), a way to add or edit your review, and the list of
/// everyone else's. Only mounted when [ContentItem.externalId] is present,
/// since that stable id is what reviews aggregate on.
class _CommunitySection extends StatefulWidget {
  const _CommunitySection({required this.item});
  final ContentItem item;

  @override
  State<_CommunitySection> createState() => _CommunitySectionState();
}

class _CommunitySectionState extends State<_CommunitySection> {
  late Future<ContentRatingSummary> _summary = ReviewsStore().summaryFor(
    widget.item.externalId,
  );
  late Future<List<Review>> _reviews = ReviewsStore().listFor(
    widget.item.externalId,
  );

  void _reload() {
    setState(() {
      _summary = ReviewsStore().summaryFor(widget.item.externalId);
      _reviews = ReviewsStore().listFor(widget.item.externalId);
    });
  }

  Future<void> _openComposer() async {
    final uid = FirebaseAuthRepository().currentUser?.uid;
    if (uid == null) {
      final signedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute<bool>(builder: (_) => const AuthPage()),
      );
      if (signedIn != true || !mounted) return;
    }
    final freshUid = FirebaseAuthRepository().currentUser?.uid;
    if (freshUid == null) return;
    var username = await AuthStore().currentUsername();
    if (username == null) {
      if (!mounted) return;
      username = await _promptForUsername();
      if (username == null) return;
    }
    if (!mounted) return;
    final existing = await ReviewsStore().myReview(
      widget.item.externalId,
      freshUid,
    );
    if (!mounted) return;
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => _ReviewComposerSheet(
        item: widget.item,
        uid: freshUid,
        username: username!,
        existing: existing,
      ),
    );
    if (submitted == true) _reload();
  }

  /// Covers an account whose username reservation failed at registration
  /// (a name-claim race) or a Google account that has none — reviewing is
  /// the first place that actually needs one, so it is asked for here.
  Future<String?> _promptForUsername() async {
    final controller = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Önce bir kullanıcı adı seç'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              prefixText: '@',
              errorText: error,
              helperText: '3-20 karakter, küçük harf, rakam, alt çizgi.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () async {
                final store = AuthStore();
                final ok = await store.setUsername(controller.text);
                if (ok) {
                  if (dialogContext.mounted) {
                    Navigator.pop(
                      dialogContext,
                      controller.text.trim().toLowerCase(),
                    );
                  }
                } else {
                  setDialogState(
                    () => error = store.lastError ?? 'Geçersiz ad.',
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Divider(height: 32),
      Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FutureBuilder<ContentRatingSummary>(
            future: _summary,
            builder: (context, snap) {
              final summary = snap.data;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    size: 20,
                    color: AppColors.brandAction,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    summary == null
                        ? 'CultureBox Puanı: —'
                        : summary.count == 0
                        ? 'CultureBox Puanı: henüz yok'
                        : 'CultureBox Puanı: ${summary.average.toStringAsFixed(1)} (${summary.count} oy)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              );
            },
          ),
          TextButton(onPressed: _openComposer, child: const Text('İncele')),
        ],
      ),
      const SizedBox(height: 12),
      FutureBuilder<List<Review>>(
        future: _reviews,
        builder: (context, snap) {
          final reviews = snap.data ?? const [];
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          if (snap.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'İncelemeler yüklenemedi.',
                  style: TextStyle(color: AppColors.muted),
                ),
                TextButton(
                  onPressed: _reload,
                  child: const Text('Tekrar dene'),
                ),
              ],
            );
          }
          if (reviews.isEmpty) {
            return const Text(
              'Henüz kimse incelememiş. İlk yorumu sen yaz.',
              style: TextStyle(color: AppColors.muted),
            );
          }
          return Column(
            children: [
              for (final review in reviews) _ReviewRow(review: review),
            ],
          );
        },
      ),
    ],
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PublicProfilePage(username: review.username),
                ),
              ),
              child: Text(
                '@${review.username}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandAction,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < review.rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 15,
                  color: AppColors.brandAction,
                ),
              ),
            ),
          ],
        ),
        if (review.text.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(review.text, style: const TextStyle(height: 1.35)),
        ],
      ],
    ),
  );
}

class _ReviewComposerSheet extends StatefulWidget {
  const _ReviewComposerSheet({
    required this.item,
    required this.uid,
    required this.username,
    required this.existing,
  });
  final ContentItem item;
  final String uid;
  final String username;
  final Review? existing;

  @override
  State<_ReviewComposerSheet> createState() => _ReviewComposerSheetState();
}

class _ReviewComposerSheetState extends State<_ReviewComposerSheet> {
  late int _rating = widget.existing?.rating ?? 0;
  late final _text = TextEditingController(text: widget.existing?.text ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Bir puan seç.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ReviewsStore().submit(
        contentId: widget.item.externalId,
        kind: widget.item.kind,
        title: widget.item.title,
        imageUrl: widget.item.imageUrl,
        uid: widget.uid,
        username: widget.username,
        rating: _rating,
        text: _text.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'İnceleme kaydedilemedi. Tekrar dene.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      MediaQuery.of(context).viewInsets.bottom + 20,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                tooltip: '${i + 1} yıldız',
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.brandAction,
                  size: 32,
                ),
              ),
            ),
          ),
          TextField(
            controller: _text,
            maxLines: 4,
            maxLength: 2000,
            decoration: const InputDecoration(
              hintText: 'Ne düşünüyorsun? (opsiyonel)',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.destructive),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandAction,
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.existing == null ? 'Paylaş' : 'Güncelle'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ContentSummary extends StatelessWidget {
  const _ContentSummary({required this.item});
  final ContentItem item;
  @override
  Widget build(BuildContext context) {
    if (item.description.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 18),
        child: Text(
          'Bu içerik için kaynakta açıklama bulunmuyor.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
      );
    }
    if (item.descriptionIsTurkish) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Text(
          item.description,
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
      );
    }
    return FutureBuilder<String?>(
      future: OnDeviceTranslationService().translateEnglishToTurkish(
        item.description,
      ),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting)
          return const Padding(
            padding: EdgeInsets.only(top: 18),
            child: Text('Türkçe çeviri hazırlanıyor…'),
          );
        if (!snap.hasData || snap.data == null)
          return const Padding(
            padding: EdgeInsets.only(top: 18),
            child: Text('Türkçe çeviri şu anda hazırlanamadı.'),
          );
        return Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Text(
            snap.data!,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        );
      },
    );
  }
}

String _resultMeta(ContentItem item) =>
    item.kind == 'Kitap' && item.creator.isNotEmpty ? item.creator : item.meta;

class _PcPriceBadge extends StatelessWidget {
  const _PcPriceBadge({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => FutureBuilder<PcPriceInfo?>(
    future: const ContentProviders().pcPrice(title),
    builder: (context, snap) {
      final price = snap.data;
      if (snap.connectionState != ConnectionState.done || price == null) {
        return const SizedBox.shrink();
      }
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(
            '\$${price.salePrice.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          if (price.onSale)
            Text(
              '\$${price.normalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.muted,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          Text(
            '${price.storeName} · CheapShark',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      );
    },
  );
}

class _BookFacts extends StatelessWidget {
  const _BookFacts({required this.item});
  final ContentItem item;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (item.publishedYear.isNotEmpty)
        _FactChip(
          icon: Icons.calendar_today_outlined,
          label: item.publishedYear,
        ),
      if (item.pageCount > 0)
        _FactChip(
          icon: Icons.menu_book_outlined,
          label: '${item.pageCount} sayfa',
        ),
    ],
  );
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.card,
      border: Border.all(color: AppColors.line),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.read),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.ink, fontSize: 12)),
      ],
    ),
  );
}

class SharePreviewPage extends StatelessWidget {
  const SharePreviewPage({super.key, required this.item});
  final ContentItem item;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      title: const Text('Paylaşım önizleme'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Paylaşmadan önce kontrol et',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Card(
          color: AppColors.card,
          child: ListTile(
            leading: SizedBox(
              width: 48,
              height: 64,
              child: CoverImage(url: item.imageUrl),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text('${item.kind} • CultureBox'),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => SharePlus.instance.share(
            ShareParams(text: '${item.title} — CultureBox listemde'),
          ),
          icon: const Icon(Icons.share_rounded),
          label: const Text('Paylaş'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandAction,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.title,
    required this.message,
    required this.icon,
    this.onRetry,
  });
  final String title, message;
  final IconData icon;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
          ],
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    ),
  );
}
