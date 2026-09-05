import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/library_store.dart';
import 'package:mobile/state/app_providers.dart';
import 'package:mobile/models/catalog.dart';
import 'package:mobile/screens/home_page.dart';
import 'package:mobile/screens/library_page.dart';
import 'package:mobile/screens/profile_page.dart';
import 'package:mobile/screens/search_page.dart';
import 'package:mobile/screens/auth_page.dart';
import 'package:mobile/theme/app_colors.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initialMode = CultureMode.watch});
  final CultureMode initialMode;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  int _tab = 0;
  CultureMode get _mode => ref.read(selectedCultureModeProvider);
  LibraryFilter _filter = LibraryFilter.all;
  int _libraryReloadToken = 0;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _synchronize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_synchronize());
  }

  Future<void> _synchronize() async {
    if (_syncing || Firebase.apps.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _syncing = true;
    try {
      await LibraryStore().synchronizeWithCloud(uid);
      if (mounted) setState(() => _libraryReloadToken++);
    } catch (_) {
      // The account's local data and outbox remain available for the next retry.
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedCultureModeProvider);
    final providers = ref.watch(contentProvidersProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            HomePage(
              providers: providers,
              mode: _mode,
              onModeChanged: _setMode,
              onOpenSearch: _openSearch,
              onOpenProfile: () => _setTab(2),
              onSeeAll: (filter) {
                setState(() {
                  _filter = filter;
                  _tab = 1;
                });
              },
            ),
            LibraryPage(
              mode: _mode,
              filter: _filter,
              reloadToken: _libraryReloadToken,
              onModeChanged: _setMode,
              onFilterChanged: (filter) => setState(() => _filter = filter),
            ),
            ProfilePage(onAuth: _openAuth),
          ],
        ),
      ),
      floatingActionButton: _tab == 2
          ? null
          : SizedBox(
              width: 58,
              height: 58,
              child: Semantics(
                label: 'İçerik ekle',
                button: true,
                child: Tooltip(
                  message: 'İçerik ekle',
                  child: FloatingActionButton(
                    onPressed: _openSearch,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const CircleBorder(),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandAction,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .2),
                            blurRadius: 12,
                            offset: const Offset(0, 9),
                          ),
                          const BoxShadow(
                            color: Color(0x77000000),
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, size: 31),
                    ),
                  ),
                ),
              ),
            ),
      // Keep the primary action reachable without covering the Listem tab.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: _BottomNav(index: _tab, onSelected: _setTab),
    );
  }

  void _setTab(int index) {
    setState(() {
      _tab = index;
      if (index == 0) {
        _filter = LibraryFilter.all;
      }
    });
  }

  void _setMode(CultureMode mode) {
    unawaited(ref.read(selectedCultureModeProvider.notifier).select(mode));
  }

  void _openSearch() {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => SearchPage(
              mode: _mode,
              providers: ref.read(contentProvidersProvider),
            ),
          ),
        )
        .then((_) {
          if (mounted) setState(() => _libraryReloadToken++);
        });
  }

  Future<void> _openAuth() async {
    await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const AuthPage()));
    if (mounted) setState(() {});
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(
                selected: index == 0,
                icon: Icons.home_rounded,
                label: 'Ana Sayfa',
                onTap: () => onSelected(0),
              ),
              _NavItem(
                selected: index == 1,
                icon: Icons.bookmark_border_rounded,
                label: 'Listem',
                onTap: () => onSelected(1),
              ),
              _NavItem(
                selected: index == 2,
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                onTap: () => onSelected(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brandAction : AppColors.muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
