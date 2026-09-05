import 'package:flutter/material.dart';

enum CultureMode { watch, play, read }

enum LibraryFilter { all, queued, continuing, saved, done }

class HomeData {
  const HomeData({
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.focusLabel,
    required this.queueItem,
    required this.continueItems,
    required this.rankedItems,
    required this.savedItems,
    required this.doneItems,
    required this.waitingCount,
    required this.waitingLabel,
    required this.weeklyCount,
    required this.weeklyLabel,
    required this.totalCount,
  });
  final String label;
  final IconData icon;
  final String subtitle;
  final String focusLabel;
  final ContentItem queueItem;
  final List<ContentItem> continueItems;
  final List<ContentItem> rankedItems;
  final List<ContentItem> savedItems;
  final List<ContentItem> doneItems;
  final String waitingCount;
  final String waitingLabel;
  final String weeklyCount;
  final String weeklyLabel;
  final String totalCount;
  String get searchHint => label == 'Oyna'
      ? 'Oyun ara'
      : label == 'Oku'
      ? 'Kitap veya yazı ara'
      : 'Film veya dizi ara';
  String get listSubtitle => label == 'Oyna'
      ? 'Oyun listen'
      : label == 'Oku'
      ? 'Okuma listen'
      : 'İzleme listen';
}

class ContentItem {
  const ContentItem({
    required this.title,
    required this.kind,
    required this.meta,
    required this.dateLabel,
    required this.imageUrl,
    this.progress = 0.0,
    this.progressLabel = '',
    this.rating = 0,
    this.description = '',
    this.creator = '',
    this.pageCount = 0,
    this.publishedYear = '',
    this.descriptionIsTurkish = false,
    this.platforms = const [],
    this.previewUrl = '',
    this.externalId = '',
  });
  final String title;
  final String kind;
  final String meta;
  final String dateLabel;
  final String imageUrl;
  final double progress;
  final String progressLabel;
  final double rating;
  final String description;
  final String creator;
  final int pageCount;
  final String publishedYear;
  final bool descriptionIsTurkish;

  /// Google Books' "preview" reader link. Only populated for `kind == 'Kitap'`.
  final String previewUrl;

  /// Stable, provider-namespaced identity (e.g. `rawg:3498`, `tvmaze:169`,
  /// `googlebooks:t1GADQAAQBAJ`) — unlike [title], this never varies with a
  /// re-release name or a typo, so CultureBox reviews aggregate correctly on
  /// "the same thing" instead of splitting across near-duplicate titles.
  /// Empty for items that predate this field (e.g. cached library rows).
  final String externalId;

  /// Platform names as reported by RAWG (e.g. "PC", "PlayStation 5"). Only
  /// populated for `kind == 'Oyun'`.
  final List<String> platforms;
}

const _emptyItem = ContentItem(
  title: '',
  kind: '',
  meta: '',
  dateLabel: '',
  imageUrl: '',
);

// Content is provided by remote providers; no demo/mock catalog ships in production.
const modeCatalog = <CultureMode, HomeData>{
  CultureMode.watch: HomeData(
    label: 'İzle',
    icon: Icons.movie_creation_outlined,
    subtitle: 'İçerik keşfet ve listene ekle.',
    focusLabel: '+ Sıraya ekle',
    queueItem: _emptyItem,
    continueItems: [],
    rankedItems: [],
    savedItems: [],
    doneItems: [],
    waitingCount: '0',
    waitingLabel: 'Sırada',
    weeklyCount: '0',
    weeklyLabel: 'Bu hafta',
    totalCount: '0',
  ),
  CultureMode.play: HomeData(
    label: 'Oyna',
    icon: Icons.sports_esports_outlined,
    subtitle: 'Oyun keşfet ve listene ekle.',
    focusLabel: '+ Sıraya ekle',
    queueItem: _emptyItem,
    continueItems: [],
    rankedItems: [],
    savedItems: [],
    doneItems: [],
    waitingCount: '0',
    waitingLabel: 'Sırada',
    weeklyCount: '0',
    weeklyLabel: 'Bu hafta',
    totalCount: '0',
  ),
  CultureMode.read: HomeData(
    label: 'Oku',
    icon: Icons.menu_book_outlined,
    subtitle: 'Kitap keşfet ve listene ekle.',
    focusLabel: '+ Sıraya ekle',
    queueItem: _emptyItem,
    continueItems: [],
    rankedItems: [],
    savedItems: [],
    doneItems: [],
    waitingCount: '0',
    waitingLabel: 'Sırada',
    weeklyCount: '0',
    weeklyLabel: 'Bu hafta',
    totalCount: '0',
  ),
};
