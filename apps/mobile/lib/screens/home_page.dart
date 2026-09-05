import 'package:flutter/material.dart';
import 'package:mobile/data/content_providers.dart';
import 'package:mobile/data/library_store.dart';
import 'package:mobile/models/catalog.dart';
import 'package:mobile/screens/search_page.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/widgets/circle_icon_button.dart';
import 'package:mobile/widgets/cover_image.dart';
import 'package:mobile/widgets/mode_chips.dart';

/// Discovery stays useful even before a user saves an item: all shelves are
/// populated from the configured provider rather than from local demo content.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.onOpenSearch,
    required this.onOpenProfile,
    required this.onSeeAll,
    this.providers = const ContentProviders(),
  });

  final CultureMode mode;
  final ValueChanged<CultureMode> onModeChanged;
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenProfile;
  final ValueChanged<LibraryFilter> onSeeAll;
  final ContentProviders providers;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ContentItem> _forYou = const [];
  List<List<ContentItem>> _shelves = const [];
  String? _error;
  bool _loading = true;
  int _request = 0;

  Color get _accent => _accentFor(widget.mode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) _load();
  }

  /// Loads discovery and every genre shelf independently: a single failing or
  /// quota-limited shelf must not blank the whole screen, and no failure mode
  /// may leave the skeleton spinning forever.
  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    final mode = widget.mode;
    final shelfSpecs = _shelfSpecsFor(mode);
    final providers = widget.providers;
    final results = await Future.wait([
      _guard(() => providers.discover(mode)),
      ...shelfSpecs.map(
        (spec) => _guard(() => providers.discoverGenre(mode, spec.genre)),
      ),
    ]);
    if (!mounted || request != _request || mode != widget.mode) return;
    final firstError = results
        .map((result) => result.error)
        .firstWhere((error) => error != null, orElse: () => null);
    setState(() {
      _loading = false;
      _forYou = results.first.items;
      _shelves = results.skip(1).map((result) => result.items).toList();
      // Only take over the screen when nothing at all could be loaded.
      _error = results.every((result) => result.items.isEmpty)
          ? firstError ?? 'İçerik bulunamadı.'
          : null;
    });
  }

  Future<({List<ContentItem> items, String? error})> _guard(
    Future<List<ContentItem>> Function() request,
  ) async {
    try {
      return (items: await request(), error: null);
    } on ContentProviderError catch (error) {
      return (items: const <ContentItem>[], error: error.message);
    } catch (_) {
      return (
        items: const <ContentItem>[],
        error: 'İçerik yüklenemedi. Daha sonra tekrar dene.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shelfSpecs = _shelfSpecsFor(widget.mode);
    final featured = _forYou.isNotEmpty ? _forYou.first : null;

    return RefreshIndicator(
      color: AppColors.brandAction,
      backgroundColor: AppColors.card,
      onRefresh: () async {
        await LibraryStore().refreshFromCloud();
        await _load();
      },
      child: CustomScrollView(
        key: PageStorageKey('home-scroll-${widget.mode.name}'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _Header(
                onOpenSearch: widget.onOpenSearch,
                onOpenProfile: widget.onOpenProfile,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: ModeChips(
                selected: widget.mode,
                onSelected: widget.onModeChanged,
              ),
            ),
          ),
          if (_loading)
            const SliverToBoxAdapter(child: _DiscoveryLoading())
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _DiscoveryError(message: _error!, onRetry: _load),
            )
          else ...[
            if (featured != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _FeaturedCard(item: featured, accent: _accent),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverToBoxAdapter(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CategoryResultsPage(
                        mode: widget.mode,
                        providers: widget.providers,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandAction,
                    side: const BorderSide(color: AppColors.line),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: Text(switch (widget.mode) {
                    CultureMode.watch => 'Film ve Dizileri Keşfet',
                    CultureMode.play => 'Tüm Oyunları Keşfet',
                    CultureMode.read => 'Tüm Kitapları Keşfet',
                  }),
                ),
              ),
            ),
            if (shelfSpecs.isNotEmpty)
              _shelf(title: 'Senin için', items: _forYou.skip(1).toList()),
            for (var index = 0; index < shelfSpecs.length; index++)
              _shelf(
                title: shelfSpecs[index].title,
                items: _shelves.length > index ? _shelves[index] : const [],
                genre: shelfSpecs[index].genre,
              ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 106)),
        ],
      ),
    );
  }

  Widget _shelf({
    required String title,
    required List<ContentItem> items,
    String? genre,
  }) {
    // This is placed inside a CustomScrollView's `slivers` list, so an empty
    // shelf must still return a sliver rather than a plain box widget.
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 27, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: title,
              accent: _accent,
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CategoryResultsPage(
                    mode: widget.mode,
                    genre: genre,
                    providers: widget.providers,
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _PosterShelf(items: items, accent: _accent),
        ),
      ],
    );
  }
}

class CategoryResultsPage extends StatefulWidget {
  const CategoryResultsPage({
    super.key,
    required this.mode,
    this.genre,
    this.providers = const ContentProviders(),
  });

  /// Null means "browse everything" — the escape hatch from a fixed set of
  /// genre shelves — rather than one specific genre.
  final CultureMode mode;
  final String? genre;
  final ContentProviders providers;

  @override
  State<CategoryResultsPage> createState() => _CategoryResultsPageState();
}

class _CategoryResultsPageState extends State<CategoryResultsPage> {
  List<ContentItem> items = const [];
  String? error;
  bool loading = true;
  String? _platform;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final genre = widget.genre;
      final value = genre == null
          ? await widget.providers.browseAll(widget.mode, platformId: _platform)
          : await widget.providers.discoverGenre(
              widget.mode,
              genre,
              platformId: _platform,
            );
      if (mounted && request == _request) setState(() => items = value);
    } on ContentProviderError catch (exception) {
      if (mounted && request == _request) {
        setState(() => error = exception.message);
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => error = 'İçerik yüklenemedi. Daha sonra tekrar dene.');
      }
    } finally {
      // An empty genre must read as "no results", never as an endless spinner.
      if (mounted && request == _request) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.genre != null
            ? _genreLabel(widget.mode, widget.genre!)
            : switch (widget.mode) {
                CultureMode.watch => 'Film ve Diziler',
                CultureMode.play => 'Tüm Oyunlar',
                CultureMode.read => 'Tüm Kitaplar',
              },
      ),
    ),
    body: Column(
      children: [
        if (widget.mode == CultureMode.play)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _PlatformFilterChips(
              selected: _platform,
              onSelected: (platform) {
                setState(() => _platform = platform);
                _load();
              },
            ),
          ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? _DiscoveryError(message: error!, onRetry: _load)
              : items.isEmpty
              ? const Center(child: Text('Bu kategoride sonuç bulunamadı.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisExtent: 260,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (_, index) => _PosterCard(
                    item: items[index],
                    accent: _accentFor(widget.mode),
                  ),
                ),
        ),
      ],
    ),
  );
}

class _PlatformFilterChips extends StatelessWidget {
  const _PlatformFilterChips({
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: ContentProviders.platformFilters.length + 1,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final label = index == 0
            ? 'Tümü'
            : ContentProviders.platformFilters.keys.elementAt(index - 1);
        final value = index == 0
            ? null
            : ContentProviders.platformFilters.values.elementAt(index - 1);
        final isSelected = selected == value;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onSelected(value),
        );
      },
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onOpenSearch, required this.onOpenProfile});
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Row(
              children: [
                _BrandMark(),
                SizedBox(width: 11),
                Flexible(
                  child: Text(
                    'CULTUREBOX',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CircleIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Arama',
            onTap: onOpenSearch,
          ),
          const SizedBox(width: 8),
          CircleIconButton(
            icon: Icons.person_outline_rounded,
            tooltip: 'Profil',
            onTap: onOpenProfile,
          ),
        ],
      ),
      const SizedBox(height: 26),
      const Text(
        'İzle. Oyna. Oku.',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 34,
          fontWeight: FontWeight.w900,
          height: .98,
          letterSpacing: -1.2,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Bugününe iyi gelecek bir şey seç.',
        style: TextStyle(color: AppColors.muted, fontSize: 15),
      ),
    ],
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: AppColors.brandAction,
      borderRadius: BorderRadius.circular(13),
    ),
    // Brand language rule: no sparkle, starburst, or decorative shimmer icons.
    child: ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Image.asset('assets/culturebox_icon.png', fit: BoxFit.cover),
    ),
  );
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item, required this.accent});
  final ContentItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(23),
    onTap: () => _openDetails(context, item),
    child: Ink(
      height: 255,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.line, width: 1.4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SharpCoverImage(item: item),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xE9000000),
                    Color(0x7A000000),
                    Color(0x18000000),
                  ],
                  stops: [0, .56, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ÖNE ÇIKAN ${item.kind.toUpperCase()}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 190,
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 29,
                        height: .95,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 205,
                    child: Text(
                      item.description.isNotEmpty
                          ? item.description
                          : item.meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE1E4E8),
                        height: 1.25,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      if (item.rating > 0) ...[
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.rating,
                          size: 19,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () async {
                          await LibraryStore().add(item);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Listene eklendi.')),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandAction,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 19),
                        label: const Text(
                          'Listeme ekle',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.accent,
    required this.onAction,
  });
  final String title;
  final Color accent;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
      ),
      TextButton.icon(
        onPressed: onAction,
        iconAlignment: IconAlignment.end,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandAction,
          padding: EdgeInsets.zero,
        ),
        label: const Text(
          'Tümünü gör',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.chevron_right_rounded, size: 20),
      ),
    ],
  );
}

class _PosterShelf extends StatelessWidget {
  const _PosterShelf({required this.items, required this.accent});
  final List<ContentItem> items;
  final Color accent;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 245,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      scrollDirection: Axis.horizontal,
      itemCount: items.length.clamp(0, 15),
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, index) => SizedBox(
        width: 126,
        child: _PosterCard(item: items[index], accent: accent),
      ),
    ),
  );
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.item, required this.accent});
  final ContentItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () => _openDetails(context, item),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CoverImage(url: item.imageUrl),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                item.kind,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
              ),
            ),
            if (item.rating > 0) ...[
              const Icon(Icons.star_rounded, color: AppColors.rating, size: 13),
              Text(
                item.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: AppColors.rating,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _DiscoveryLoading extends StatelessWidget {
  const _DiscoveryLoading();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 100),
    child: Center(
      child: CircularProgressIndicator(color: AppColors.brandAction),
    ),
  );
}

class _DiscoveryError extends StatelessWidget {
  const _DiscoveryError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.muted, size: 42),
          const SizedBox(height: 12),
          const Text(
            'İçerikler şu an yüklenemedi.',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onRetry, child: const Text('Tekrar dene')),
        ],
      ),
    ),
  );
}

Color _accentFor(CultureMode mode) => switch (mode) {
  CultureMode.watch => AppColors.watch,
  CultureMode.play => AppColors.play,
  CultureMode.read => AppColors.read,
};

List<({String title, String genre})> _shelfSpecsFor(CultureMode mode) =>
    switch (mode) {
      CultureMode.watch => const [
        (title: 'Dram', genre: 'Drama'),
        (title: 'Komedi', genre: 'Comedy'),
        (title: 'Suç', genre: 'Crime'),
        (title: 'Aksiyon', genre: 'Action'),
        (title: 'Gerilim', genre: 'Thriller'),
        (title: 'Bilim kurgu', genre: 'Science-Fiction'),
      ],
      CultureMode.play => const [
        (title: 'Aksiyon oyunları', genre: 'action'),
        (title: 'Macera oyunları', genre: 'adventure'),
        (title: 'RPG', genre: 'rpg'),
        (title: 'Strateji oyunları', genre: 'strategy'),
        (title: 'Nişancı oyunlar', genre: 'shooter'),
        (title: 'Bağımsız oyunlar', genre: 'indie'),
      ],
      CultureMode.read => const [
        (title: 'Popüler kurgu', genre: 'fiction'),
        (title: 'Bilim kurgu & fantastik', genre: 'science-fiction'),
        (title: 'Kişisel gelişim', genre: 'self-help'),
        (title: 'Tarih & biyografi', genre: 'history'),
        (title: 'Klasikler', genre: 'classics'),
      ],
    };

String _genreLabel(CultureMode mode, String genre) {
  for (final spec in _shelfSpecsFor(mode)) {
    if (spec.genre == genre) return spec.title;
  }
  return genre;
}

void _openDetails(BuildContext context, ContentItem item) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ContentDetailPage(item: item)),
  );
}
