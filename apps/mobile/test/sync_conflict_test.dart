import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/sync_conflict_resolver.dart';

void main() {
  test('newer local mutation wins deterministically', () {
    const resolver = SyncConflictResolver();
    final result = resolver.resolve(
      local: {'status': 'done', 'updatedAt': '2026-09-03T10:00:00Z'},
      remote: {'status': 'queued', 'updatedAt': '2026-09-03T09:00:00Z'},
    );
    expect(result['status'], 'done');
  });
}
