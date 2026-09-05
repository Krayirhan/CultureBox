import 'package:flutter/material.dart';
import 'package:mobile/models/catalog.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onComplete,
    required this.onAuth,
  });

  final ValueChanged<Set<CultureMode>> onComplete;
  final VoidCallback onAuth;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  final _selected = <CultureMode>{};
  int _page = 0;
  bool _notifications = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      widget.onComplete(_selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  const Text(
                    'CultureBox',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    '${_page + 1}/3',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => widget.onComplete(_selected),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Atla'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _WelcomeStep(onNext: _next),
                  _CategoryStep(
                    selected: _selected,
                    onChanged: (mode) => setState(() {
                      _selected.contains(mode)
                          ? _selected.remove(mode)
                          : _selected.add(mode);
                    }),
                  ),
                  _NotificationStep(
                    enabled: _notifications,
                    onChanged: (value) =>
                        setState(() => _notifications = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _page == 1 && _selected.isEmpty ? null : _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandAction,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_page == 2 ? 'CultureBox’a başla' : 'Devam et'),
                ),
              ),
            ),
            TextButton(
              onPressed: widget.onAuth,
              child: const Text('Zaten hesabın var mı? Giriş yap'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => const _StepLayout(
    brandIcon: true,
    title:
        'İzleyeceklerini, oynayacaklarını ve okuyacaklarını tek yerde topla.',
    body: 'İzlemek, oynamak, okumak ve gitmek istediklerini sade bir listede takip et.',
  );
}

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({required this.selected, required this.onChanged});
  final Set<CultureMode> selected;
  final ValueChanged<CultureMode> onChanged;

  @override
  Widget build(BuildContext context) => _StepLayout(
    title: 'Neler ilgini çekiyor?',
    body: 'İstersen birden fazla alan seçebilirsin.',
    child: Column(
      children: [
        for (final entry in const [
          (CultureMode.watch, 'İzle', Icons.movie_outlined),
          (CultureMode.play, 'Oyna', Icons.sports_esports_outlined),
          (CultureMode.read, 'Oku', Icons.menu_book_outlined),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ChoiceChip(
              avatar: Icon(entry.$3),
              label: Text(entry.$2),
              selected: selected.contains(entry.$1),
              onSelected: (_) => onChanged(entry.$1),
              selectedColor: AppColors.brandActionSoft,
            ),
          ),
      ],
    ),
  );
}

class _NotificationStep extends StatelessWidget {
  const _NotificationStep({required this.enabled, required this.onChanged});
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _StepLayout(
    icon: Icons.notifications_none_rounded,
    title: 'Hatırlatıcıları açalım mı?',
    body: 'Listendeki içeriklere geri dönmen için bildirim gönderebiliriz. Bunu daha sonra Profil’den değiştirebilirsin.',
    child: SwitchListTile.adaptive(
      title: const Text('Bildirimlere izin ver'),
      value: enabled,
      onChanged: (value) async {
        if (value) {
          final status = await Permission.notification.request();
          onChanged(status.isGranted);
        } else {
          onChanged(false);
        }
      },
    ),
  );
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({
    this.icon,
    this.brandIcon = false,
    required this.title,
    required this.body,
    this.child,
  });
  final IconData? icon;
  final bool brandIcon;
  final String title;
  final String body;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
    child: Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null || brandIcon) ...[
              CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.brandActionSoft,
                child: brandIcon
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(38),
                        child: Image.asset(
                          'assets/culturebox_icon.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(icon, color: AppColors.brandAction, size: 38),
              ),
              const SizedBox(height: 28),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 16,
                height: 1.45,
              ),
            ),
            if (child != null) ...[const SizedBox(height: 28), child!],
          ],
        ),
      ),
    ),
  );
}
