import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/data/auth_store.dart';
import 'package:mobile/data/firebase_auth_repository.dart';
import 'package:mobile/data/library_store.dart';
import 'package:mobile/data/username_store.dart';
import 'package:mobile/models/public_profile.dart';
import 'package:mobile/screens/public_profile_page.dart';
import 'package:share_plus/share_plus.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.onAuth});
  final Future<void> Function()? onAuth;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<_ProfileData> _data = _load();
  bool _savingVisibility = false;

  Future<_ProfileData> _load() async {
    final name = await AuthStore().currentDisplayName();
    final email = await AuthStore().currentEmail();
    final uid = FirebaseAuthRepository().currentUser?.uid;
    final authStore = AuthStore();
    final profile = uid == null
        ? null
        : await UsernameStore().profileFor(uid) ??
              (await authStore.ensureUsernameForCurrentUser(email: email) ==
                      null
                  ? null
                  : await UsernameStore().profileFor(uid));
    return _ProfileData(name: name, email: email, uid: uid, profile: profile);
  }

  void _reload() => setState(() => _data = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Profil yüklenemedi. Bağlantını kontrol edip tekrar dene.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          );
        }
        final name = snapshot.data?.name;
        final email = snapshot.data?.email;
        final uid = snapshot.data?.uid;
        final profile = snapshot.data?.profile;
        final accountName = _accountName(
          authName: name,
          profile: profile,
          email: email,
        );
        return RefreshIndicator(
          color: AppColors.brandAction,
          backgroundColor: AppColors.card,
          onRefresh: () async {
            await LibraryStore().refreshFromCloud();
            _reload();
            await _data;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                'Profil',
                style: TextStyle(
                  color: AppColors.ink,
                  fontFamily: 'serif',
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 16),
              _AccountCard(
                initial: _initial(accountName),
                name: accountName,
                email: email ?? 'Bu cihazda yerel liste',
              ),
              const SizedBox(height: 14),
              if (profile != null)
                _CommunityCard(
                  username: profile.username,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          PublicProfilePage(username: profile.username),
                    ),
                  ),
                )
              else if (email != null)
                _CommunityCard(
                  username: 'Profilini oluştur',
                  empty: true,
                  onTap: () => _showUsernameDialog(context),
                ),
              const SizedBox(height: 22),
              const _SectionLabel('Ayarlar'),
              const SizedBox(height: 8),
              _SettingsGroup(
                children: [
                  _SettingsRow(
                    icon: Icons.cloud_outlined,
                    title: 'Hesap ve senkron',
                    subtitle: email == null
                        ? 'Hesabına bağlan ve listeni koru'
                        : 'Bulut listeni şimdi yenile',
                    onTap: email == null
                        ? () async {
                            await widget.onAuth?.call();
                            if (mounted) _reload();
                          }
                        : () => _synchronize(),
                  ),
                  if (email != null)
                    _SettingsRow(
                      icon: Icons.logout_rounded,
                      title: 'Çıkış yap',
                      subtitle: 'Hesabından güvenli çıkış yap',
                      onTap: () async {
                        await AuthStore().signOut();
                        if (mounted) _reload();
                      },
                    ),
                ],
              ),
              if (profile != null) ...[
                const SizedBox(height: 22),
                const _SectionLabel('Görünürlük'),
                const SizedBox(height: 8),
                _VisibilityCard(
                  libraryVisible: profile.libraryVisible,
                  reviewsVisible: profile.reviewsVisible,
                  onLibraryChanged: uid == null || _savingVisibility
                      ? null
                      : (value) => _setVisibility(uid, library: value),
                  onReviewsChanged: uid == null || _savingVisibility
                      ? null
                      : (value) => _setVisibility(uid, reviews: value),
                ),
              ],
              const SizedBox(height: 22),
              const _SectionLabel('Veri ve güvenlik'),
              const SizedBox(height: 8),
              _SettingsGroup(
                children: [
                  _SettingsRow(
                    icon: Icons.ios_share_rounded,
                    title: 'Verilerimi dışa aktar',
                    subtitle: 'Listeyi dosya olarak al',
                    onTap: () => _export(context),
                  ),
                  _SettingsRow(
                    icon: Icons.delete_outline_rounded,
                    title: 'Cihazdaki listeyi temizle',
                    subtitle: 'Bulut hesabındaki liste silinmez',
                    danger: true,
                    onTap: () => _delete(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingsGroup(
                children: [
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    title: 'Hakkında',
                    subtitle: 'İzle. Oyna. Oku.',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'CultureBox',
                      children: const [
                        Text(
                          'Film, dizi, oyun ve kitaplarını tek yerde takip et. Listelerini düzenle ve toplulukla incelemelerini paylaş.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _displayName(String email) => email.split('@').first;

  String _accountName({
    required String? authName,
    required PublicProfile? profile,
    required String? email,
  }) {
    if (authName?.trim().isNotEmpty == true) return authName!.trim();
    if (profile?.displayName.trim().isNotEmpty == true) {
      return profile!.displayName.trim();
    }
    if (profile?.username.isNotEmpty == true) return '@${profile!.username}';
    return email == null ? 'Misafir' : _displayName(email);
  }

  String _initial(String? email) {
    final name = email == null ? 'M' : _displayName(email);
    return name.isEmpty ? 'U' : name.substring(0, 1).toUpperCase();
  }

  Future<void> _export(BuildContext context) async {
    try {
      final items = await LibraryStore().read();
      final document = const JsonEncoder.withIndent('  ').convert({
        'formatVersion': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'items': items
            .map(
              (entry) => {
                ...entry.toJson(),
                'externalId': entry.item.externalId,
                'meta': entry.item.meta,
                'dateLabel': entry.item.dateLabel,
                'imageUrl': entry.item.imageUrl,
                'description': entry.item.description,
                'creator': entry.item.creator,
                'pageCount': entry.item.pageCount,
                'publishedYear': entry.item.publishedYear,
                'platforms': entry.item.platforms,
                'previewUrl': entry.item.previewUrl,
                'rating': entry.item.rating,
                'progress': entry.item.progress,
                'progressLabel': entry.item.progressLabel,
              },
            )
            .toList(),
      });
      if (!context.mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          title: 'CultureBox listem',
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(document)),
              mimeType: 'application/json',
            ),
          ],
          fileNameOverrides: const ['culturebox-listem.json'],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Liste dışa aktarılamadı. Tekrar dene.'),
          ),
        );
      }
    }
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cihazdaki liste temizlensin mi?'),
        content: const Text(
          'Bu cihazdaki liste temizlenecek. Bulut hesabındaki kayıtlar korunur ve senkronizasyonla tekrar gelebilir.',
        ),
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
    if (confirmed == true) {
      await LibraryStore().clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cihazdaki kayıtlar silindi.')),
        );
      }
    }
  }

  Future<void> _synchronize() async {
    try {
      await LibraryStore().refreshFromCloud();
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Senkronizasyon denendi. Çevrimdışı değişiklikler bağlantı geldiğinde gönderilir.',
          ),
        ),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senkronizasyon tamamlanamadı. Tekrar dene.'),
          ),
        );
    }
  }

  Future<void> _setVisibility(
    String uid, {
    bool? library,
    bool? reviews,
  }) async {
    setState(() => _savingVisibility = true);
    try {
      await UsernameStore().setVisibility(
        uid: uid,
        libraryVisible: library,
        reviewsVisible: reviews,
      );
      if (mounted) _reload();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görünürlük kaydedilemedi. Tekrar dene.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _savingVisibility = false);
    }
  }

  Future<void> _showUsernameDialog(BuildContext context) async {
    final controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Topluluk profilin'),
        content: TextField(
          controller: controller,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Kullanıcı adı',
            prefixText: '@',
            helperText: '3-20 karakter: küçük harf, rakam veya alt çizgi',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (username == null || username.trim().isEmpty || !mounted) return;
    final success = await AuthStore().setUsername(username);
    if (!mounted) return;
    if (success) {
      _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthStore().lastError ?? 'Profil oluşturulamadı.'),
        ),
      );
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.initial,
    required this.name,
    required this.email,
  });

  final String initial;
  final String name;
  final String email;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.brandActionSoft,
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.brandAction,
              fontFamily: 'serif',
              fontSize: 26,
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
                name,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(email, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.username,
    required this.onTap,
    this.empty = false,
  });

  final String username;
  final VoidCallback onTap;
  final bool empty;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.communitySurface,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.communityLine),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.communityAccent),
              ),
              child: const Icon(Icons.public_rounded, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Topluluk profilim',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    empty ? 'Bir kullanıcı adı seçerek aç' : '@$username',
                    style: const TextStyle(color: AppColors.communityAccent),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.ink),
          ],
        ),
      ),
    ),
  );
}

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({
    required this.libraryVisible,
    required this.reviewsVisible,
    required this.onLibraryChanged,
    required this.onReviewsChanged,
  });

  final bool libraryVisible;
  final bool reviewsVisible;
  final ValueChanged<bool>? onLibraryChanged;
  final ValueChanged<bool>? onReviewsChanged;

  @override
  Widget build(BuildContext context) => _SettingsGroup(
    children: [
      _VisibilityRow(
        icon: Icons.visibility_outlined,
        title: 'Kütüphanemi göster',
        value: libraryVisible,
        onChanged: onLibraryChanged,
      ),
      const Divider(height: 1, indent: 68, color: AppColors.line),
      _VisibilityRow(
        icon: Icons.rate_review_outlined,
        title: 'İncelemelerimi göster',
        value: reviewsVisible,
        onChanged: onReviewsChanged,
      ),
    ],
  );
}

class _VisibilityRow extends StatelessWidget {
  const _VisibilityRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    secondary: Icon(icon, color: AppColors.muted),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    value: value,
    activeTrackColor: AppColors.brandAction,
    onChanged: onChanged,
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.destructive : AppColors.ink;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.muted, fontSize: 13),
      ),
      trailing: onTap == null || danger
          ? null
          : const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
      onTap: onTap,
    );
  }
}

class _ProfileData {
  const _ProfileData({
    required this.name,
    required this.email,
    required this.uid,
    required this.profile,
  });
  final String? name;
  final String? email;
  final String? uid;
  final PublicProfile? profile;
}
