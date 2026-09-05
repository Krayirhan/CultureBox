import 'package:flutter/material.dart';
import 'package:mobile/models/catalog.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/widgets/cover_image.dart';
import 'package:mobile/widgets/mode_chips.dart';
import 'package:mobile/data/library_store.dart';
import 'package:mobile/screens/search_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.mode,
    required this.filter,
    required this.reloadToken,
    required this.onModeChanged,
    required this.onFilterChanged,
    this.store,
  });

  final CultureMode mode;
  final LibraryFilter filter;
  final int reloadToken;
  final ValueChanged<CultureMode> onModeChanged;
  final ValueChanged<LibraryFilter> onFilterChanged;
  final LibraryStore? store;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<StoredLibraryItem> _stored = const [];
  bool _loading = true;
  String? _error;
  LibraryStore get _store => widget.store ?? LibraryStore();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        oldWidget.filter != widget.filter ||
        oldWidget.reloadToken != widget.reloadToken) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final items = await _store.read();
      if (mounted) {
        setState(() {
          _stored = items;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Listen yüklenemedi. Tekrar dene.';
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _store.refreshFromCloud();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = modeCatalog[widget.mode]!;
    final entries = _entriesForStored(widget.mode, widget.filter);

    return RefreshIndicator(
      color: AppColors.brandAction,
      backgroundColor: AppColors.card,
      onRefresh: _refresh,
      child: CustomScrollView(
        key: const PageStorageKey('library-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Listem',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontFamily: 'serif',
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${data.listSubtitle}  •  ${entries.length} içerik',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(
              child: ModeChips(
                selected: widget.mode,
                onSelected: widget.onModeChanged,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _FilterChips(
                selected: widget.filter,
                onSelected: widget.onFilterChanged,
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            )
          else if (entries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              sliver: SliverList.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _LibraryRow(
                  entry: entries[index],
                  store: _store,
                  onChanged: _load,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_LibraryEntry> _entriesForStored(
    CultureMode mode,
    LibraryFilter selected,
  ) {
    final kinds = switch (mode) {
      CultureMode.play => const {'Oyun'},
      CultureMode.watch => const {'Dizi', 'Film'},
      CultureMode.read => const {'Kitap'},
    };
    final filtered = _stored.where(
      (e) =>
          kinds.contains(e.item.kind) &&
          (selected == LibraryFilter.all || e.status.name == selected.name),
    );
    return filtered
        .map((e) => _LibraryEntry(_statusLabel(mode, e.status), e.item))
        .toList();
  }

  String _statusLabel(CultureMode mode, LibraryStatus status) {
    final verb = switch (mode) {
      CultureMode.watch => ('İzleyeceklerim', 'İzliyorum', 'İzlediklerim'),
      CultureMode.play => ('Oynayacaklarım', 'Oynuyorum', 'Oynadıklarım'),
      CultureMode.read => ('Okuyacaklarım', 'Okuyorum', 'Okuduklarım'),
    };
    return switch (status) {
      LibraryStatus.queued => verb.$1,
      LibraryStatus.continuing => verb.$2,
      LibraryStatus.done => verb.$3,
      LibraryStatus.saved => 'Kaydedilen',
      LibraryStatus.dropped => 'Bırakılan',
    };
  }
}

class _LibraryEntry {
  const _LibraryEntry(this.status, this.item);

  final String status;
  final ContentItem item;
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final LibraryFilter selected;
  final ValueChanged<LibraryFilter> onSelected;

  static const _filters = <LibraryFilter, String>{
    LibraryFilter.all: 'Tümü',
    LibraryFilter.queued: 'Sırada',
    LibraryFilter.continuing: 'Devam',
    LibraryFilter.saved: 'Kaydedilen',
    LibraryFilter.done: 'Bitti',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters.keys.elementAt(index);
          final isSelected = filter == selected;
          return Material(
            color: isSelected ? AppColors.brandAction : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => onSelected(filter),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.brandAction : AppColors.line,
                  ),
                ),
                child: Text(
                  _filters[filter]!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.ink,
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({
    required this.entry,
    required this.store,
    required this.onChanged,
  });

  final _LibraryEntry entry;
  final LibraryStore store;
  final Future<void> Function() onChanged;

  Future<void> _remove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('İçerik silinsin mi?'),
        content: Text(entry.item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: AppColors.background,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _change(
      context,
      () => store.remove(entry.item),
      'İçerik listeden silindi.',
    );
  }

  Future<void> _change(
    BuildContext context,
    Future<void> Function() mutation,
    String success,
  ) async {
    try {
      await mutation();
      await onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Değişiklik kaydedilemedi. Tekrar dene.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => ContentDetailPage(item: item)),
      ),
      onLongPress: () => _remove(context),
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 78,
              height: 92,
              child: CoverImage(url: item.imageUrl),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.progressLabel.isEmpty
                          ? '${item.kind}${item.meta.isEmpty ? '' : '  •  ${item.meta}'}'
                          : item.progressLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandActionSoft,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            entry.status,
                            style: const TextStyle(
                              color: AppColors.brandAction,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (item.progress > 0) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: item.progress,
                                minHeight: 4,
                                backgroundColor: AppColors.line,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.brandAction,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'İçerik işlemleri',
              onSelected: (value) async {
                if (value == 'remove') {
                  await _remove(context);
                  return;
                }
                await _change(
                  context,
                  () => store.update(
                    item,
                    status: LibraryStatus.values.byName(value),
                  ),
                  'Durum güncellendi.',
                );
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'queued', child: Text('Sırada')),
                PopupMenuItem(value: 'continuing', child: Text('Devam ediyor')),
                PopupMenuItem(value: 'saved', child: Text('Kaydedilen')),
                PopupMenuItem(value: 'done', child: Text('Tamamlandı')),
                PopupMenuItem(value: 'dropped', child: Text('Bırakıldı')),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    'Listeden sil',
                    style: TextStyle(color: AppColors.destructive),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, size: 36, color: AppColors.muted),
          SizedBox(height: 12),
          Text(
            'Bu bölüm boş',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Kaydettiğin şeyler burada toplanır.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
