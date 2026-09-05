import 'package:shared_preferences/shared_preferences.dart';

/// Last-searched queries, kept per culture mode so a "Book" search does not
/// surface as a suggestion while browsing games.
class RecentSearchesStore {
  static const _maxEntries = 8;

  Future<List<String>> read(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key(mode)) ?? const [];
  }

  Future<void> add(String mode, String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_key(mode)) ?? <String>[];
    existing.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    existing.insert(0, trimmed);
    await prefs.setStringList(_key(mode), existing.take(_maxEntries).toList());
  }

  Future<void> clear(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(mode));
  }

  String _key(String mode) => 'recent_searches_$mode';
}
