class ContentProviderError implements Exception {
  const ContentProviderError(this.message);
  final String message;

  @override
  String toString() => message;
}
