class ReleaseEnvironmentError implements Exception {
  const ReleaseEnvironmentError(this.missing);
  final List<String> missing;
  @override
  String toString() => 'Missing release environment: ${missing.join(', ')}';
}

/// Validates required production inputs without logging their values.
class ReleaseEnvironment {
  const ReleaseEnvironment({required this.values});
  final Map<String, String> values;

  void validate({bool requireProviderKeys = true}) {
    final names = <String>['FIREBASE_PROJECT_ID'];
    if (requireProviderKeys) {
      names.addAll(['RAWG_API_KEY', 'GOOGLE_BOOKS_API_KEY']);
    }
    final missing = names
        .where((name) => (values[name] ?? '').trim().isEmpty)
        .toList();
    if (missing.isNotEmpty) throw ReleaseEnvironmentError(missing);
  }
}
