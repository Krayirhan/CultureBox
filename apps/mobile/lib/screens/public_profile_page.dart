import 'package:flutter/material.dart';
import 'package:mobile/data/public_profile_store.dart';
import 'package:mobile/models/public_profile.dart';
import 'package:mobile/models/review.dart';
import 'package:mobile/models/catalog.dart';
import 'package:mobile/screens/search_page.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/widgets/cover_image.dart';
import 'package:share_plus/share_plus.dart';

/// The `@handle` page: what a user watched/played/read and the reviews they
/// wrote, each shown only if that user left it visible. Read-only — this is
/// never how the signed-in user edits their own data.
class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({super.key, required this.username});
  final String username;

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  late Future<_ProfileBundle?> _bundle = _load();
  int _selectedSection = 0;

  Future<_ProfileBundle?> _load() async {
    final store = PublicProfileStore();
    final profile = await store.fetchByUsername(widget.username);
    if (profile == null) return null;
    final library = profile.libraryVisible
        ? await store.libraryFor(profile.uid)
        : const <PublicLibraryEntry>[];
    final reviews = profile.reviewsVisible
        ? await store.reviewsFor(profile.uid)
        : const <Review>[];
    return _ProfileBundle(profile: profile, library: library, reviews: reviews);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      title: Text('@${widget.username}'),
      actions: [
        IconButton(
          tooltip: 'Profili paylaş',
          icon: const Icon(Icons.ios_share_rounded),
          onPressed: () => SharePlus.instance.share(
            ShareParams(
              text: 'CultureBox profilime göz at: @${widget.username}',
            ),
          ),
        ),
      ],
    ),
    body: FutureBuilder<_ProfileBundle?>(
      future: _bundle,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        // A load failure (permission, network, a not-yet-ready index) must
        // read as its own error, never silently as "no such user" — the two
        // call for different next steps from whoever is looking at this.
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Profil yüklenemedi. Bağlantını kontrol edip tekrar dene.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _bundle = _load()),
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          );
        }
        final bundle = snap.data;
        if (bundle == null) {
          return const Center(
            child: Text(
              'Bu kullanıcı adı bulunamadı.',
              style: TextStyle(color: AppColors.muted),
            ),
          );
        }
        final profile = bundle.profile;
        return RefreshIndicator(
          color: AppColors.brandAction,
          backgroundColor: AppColors.card,
          onRefresh: () async {
            setState(() => _bundle = _load());
            await _bundle;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.brandActionSoft,
                      child: Text(
                        (profile.displayName.isEmpty
                                ? profile.username
                                : profile.displayName)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.brandAction,
                          fontFamily: 'serif',
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName.isEmpty
                                ? profile.username
                                : profile.displayName,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '@${profile.username}',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'Kütüphane',
                      value: bundle.library.length,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      label: 'İnceleme',
                      value: bundle.reviews.length,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      label: 'Tamamlandı',
                      value: bundle.library
                          .where((e) => e.status == 'done')
                          .length,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _ProfileTabs(
                selectedIndex: _selectedSection,
                onChanged: (index) => setState(() => _selectedSection = index),
              ),
              const SizedBox(height: 18),
              _ProfileSection(
                selectedIndex: _selectedSection,
                profile: profile,
                library: bundle.library,
                reviews: bundle.reviews,
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selectedIndex, required this.onChanged});
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [_tab('Özet', 0), _tab('Kütüphane', 1), _tab('İncelemeler', 2)],
    ),
  );

  Widget _tab(String label, int index) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selectedIndex == index
              ? AppColors.brandAction
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selectedIndex == index
                ? AppColors.background
                : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.selectedIndex,
    required this.profile,
    required this.library,
    required this.reviews,
  });
  final int selectedIndex;
  final PublicProfile profile;
  final List<PublicLibraryEntry> library;
  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    if (selectedIndex == 1) return _library(all: true);
    if (selectedIndex == 2) return _reviews(all: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Son eklenenler', icon: Icons.menu_book_outlined),
        const SizedBox(height: 10),
        _library(all: false),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Son incelemeler', icon: Icons.edit_note_rounded),
        const SizedBox(height: 10),
        _reviews(all: false),
      ],
    );
  }

  Widget _library({required bool all}) {
    if (!profile.libraryVisible) {
      return const _EmptySection(
        icon: Icons.visibility_off_outlined,
        text: 'Kütüphane bu profilde gizli.',
      );
    }
    if (library.isEmpty) {
      return const _EmptySection(
        icon: Icons.auto_stories_outlined,
        text: 'Henüz kütüphanesine bir şey eklenmemiş.',
      );
    }
    final entries = all ? library : library.take(3);
    return Column(
      children: entries.map((entry) => _LibraryTile(entry: entry)).toList(),
    );
  }

  Widget _reviews({required bool all}) {
    if (!profile.reviewsVisible) {
      return const _EmptySection(
        icon: Icons.visibility_off_outlined,
        text: 'İncelemeler bu profilde gizli.',
      );
    }
    if (reviews.isEmpty) {
      return const _EmptySection(
        icon: Icons.rate_review_outlined,
        text: 'Henüz bir inceleme paylaşmamış.',
      );
    }
    final items = all ? reviews : reviews.take(3);
    return Column(
      children: items.map((review) => _ReviewTile(review: review)).toList(),
    );
  }
}

class _ProfileBundle {
  const _ProfileBundle({
    required this.profile,
    required this.library,
    required this.reviews,
  });
  final PublicProfile profile;
  final List<PublicLibraryEntry> library;
  final List<Review> reviews;
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: AppColors.brandAction,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 21, color: AppColors.brandAction),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
      ),
    ],
  );
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppColors.muted)),
        ),
      ],
    ),
  );
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({required this.entry});
  final PublicLibraryEntry entry;

  static const _statusLabels = {
    'queued': 'Sırada',
    'continuing': 'Devam ediyor',
    'saved': 'Kaydedilen',
    'done': 'Tamamlandı',
    'dropped': 'Bırakıldı',
  };

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => _openContent(context, entry.toContentItem()),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 46,
              height: 62,
              child: CoverImage(
                url: entry.imageUrl,
                fallbackIcon: _kindIcon(entry.kind),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${entry.kind}  •  ${_statusLabels[entry.status] ?? entry.status}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: review.contentId.isEmpty
        ? null
        : () => _openContent(context, review.toContentItem()),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (review.contentTitle.isNotEmpty) ...[
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 36,
                    height: 48,
                    child: CoverImage(
                      url: review.contentImageUrl,
                      fallbackIcon: _kindIcon(review.contentKind),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.contentTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (review.contentKind.isNotEmpty)
                        Text(
                          review.contentKind,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
            const SizedBox(height: 9),
          ],
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
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(review.text, style: const TextStyle(height: 1.35)),
          ],
        ],
      ),
    ),
  );
}

void _openContent(BuildContext context, ContentItem item) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => ContentDetailPage(item: item)),
  );
}

IconData _kindIcon(String kind) => switch (kind) {
  'Oyun' => Icons.sports_esports_outlined,
  'Kitap' => Icons.menu_book_outlined,
  _ => Icons.movie_filter_outlined,
};
