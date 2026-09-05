import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:mobile/shell/app_shell.dart';
import 'package:mobile/screens/onboarding_page.dart';
import 'package:mobile/theme/app_colors.dart';
import 'package:mobile/models/catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/screens/guest_entry_page.dart';
import 'package:mobile/data/firebase_bootstrap.dart';
import 'package:mobile/data/content_providers.dart';
import 'package:mobile/state/app_providers.dart';
import 'package:mobile/screens/auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  final preferences = await SharedPreferences.getInstance();
  final firebaseSignedIn =
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;
  // Cloud recovery runs after the first frame; an offline session must never
  // hold the native splash screen open.
  final modeIndex = preferences.getInt('selected_mode') ?? 0;
  runApp(
    CultureBoxApp(
      initialOnboardingComplete:
          preferences.getBool('onboarding_complete') ?? false,
      // “Git” is paused for now; old saved preferences safely land on Oku.
      initialMode: CultureMode.values[modeIndex.clamp(0, 2)],
      guestMode:
          firebaseSignedIn || (preferences.getBool('guest_mode') ?? false),
    ),
  );
}

class CultureBoxApp extends StatefulWidget {
  const CultureBoxApp({
    super.key,
    this.initialOnboardingComplete = false,
    this.initialMode = CultureMode.watch,
    this.guestMode = false,
    this.providers = const ContentProviders(),
  });

  final bool initialOnboardingComplete;
  final CultureMode initialMode;
  final bool guestMode;
  final ContentProviders providers;

  @override
  State<CultureBoxApp> createState() => _CultureBoxAppState();
}

class _CultureBoxAppState extends State<CultureBoxApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late bool _onboardingComplete = widget.initialOnboardingComplete;
  late bool _guestMode = widget.guestMode;
  late CultureMode _initialMode = widget.initialMode;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        initialCultureModeProvider.overrideWithValue(_initialMode),
        contentProvidersProvider.overrideWithValue(widget.providers),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'CultureBox',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.brandAction,
            brightness: Brightness.dark,
            surface: AppColors.surface,
          ),
        ),
        home: _onboardingComplete
            ? (_guestMode
                  ? AppShell(initialMode: _initialMode)
                  : GuestEntryPage(
                      onGuestContinue: _enterGuest,
                      onAuth: _openAuth,
                    ))
            : _StartupGate(
                onComplete: (modes) async {
                  final preferences = await SharedPreferences.getInstance();
                  await preferences.setBool('onboarding_complete', true);
                  await preferences.setBool('guest_mode', false);
                  if (modes.isNotEmpty) {
                    await preferences.setInt(
                      'selected_mode',
                      modes.first.index,
                    );
                    _initialMode = modes.first;
                  }
                  if (mounted) setState(() => _onboardingComplete = true);
                },
                onAuth: _openAuthFromOnboarding,
              ),
      ),
    );
  }

  Future<void> _enterGuest() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('guest_mode', true);
    if (mounted) setState(() => _guestMode = true);
  }

  Future<void> _openAuth() async {
    final authenticated = await _navigatorKey.currentState!.push<bool>(
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
    if (authenticated != true || !mounted) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('guest_mode', true);
    setState(() => _guestMode = true);
  }

  Future<void> _openAuthFromOnboarding() async {
    final authenticated = await _navigatorKey.currentState!.push<bool>(
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
    if (authenticated != true || !mounted) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_complete', true);
    await preferences.setBool('guest_mode', true);
    setState(() {
      _onboardingComplete = true;
      _guestMode = true;
    });
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({required this.onComplete, required this.onAuth});
  final ValueChanged<Set<CultureMode>> onComplete;
  final VoidCallback onAuth;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _splash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _splash = false);
    });
  }

  @override
  Widget build(BuildContext context) => _splash
      ? const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Text(
              'CultureBox',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 38,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        )
      : OnboardingPage(onComplete: widget.onComplete, onAuth: widget.onAuth);
}

