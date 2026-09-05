import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/content_providers.dart';
import 'package:mobile/models/catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

final initialCultureModeProvider = Provider<CultureMode>(
  (ref) => CultureMode.watch,
);
final contentProvidersProvider = Provider<ContentProviders>(
  (ref) => const ContentProviders(),
);

final selectedCultureModeProvider =
    NotifierProvider<SelectedCultureMode, CultureMode>(
      SelectedCultureMode.new,
      dependencies: [initialCultureModeProvider],
    );

class SelectedCultureMode extends Notifier<CultureMode> {
  Future<void> _writes = Future<void>.value();

  @override
  CultureMode build() => ref.watch(initialCultureModeProvider);

  Future<void> select(CultureMode mode) {
    state = mode;
    // Serialize rapid mode changes so the last choice also wins on disk.
    _writes = _writes.catchError((Object _) {}).then((_) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt('selected_mode', mode.index);
    });
    return _writes;
  }
}
