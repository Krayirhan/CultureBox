class SyncConflictResolver {
  const SyncConflictResolver();

  /// Explicitly newer user mutation wins; ties are resolved locally so the
  /// result is deterministic and never silently overwrites with metadata.
  Map<String, Object?> resolve({
    required Map<String, Object?> local,
    required Map<String, Object?> remote,
  }) {
    final localTime = _time(local['updatedAt']);
    final remoteTime = _time(remote['updatedAt']);
    if (localTime.compareTo(remoteTime) >= 0) {
      return Map<String, Object?>.from(local);
    }
    return Map<String, Object?>.from(remote);
  }

  DateTime _time(Object? value) => value is DateTime
      ? value
      : DateTime.tryParse(value?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
}
