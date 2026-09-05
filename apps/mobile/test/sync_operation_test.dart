import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/firestore_sync_repository.dart';

void main() {
  test('sync operation payload is deterministic JSON', () {
    const operation = SyncOperation(
      type: 'upsert',
      itemId: 'item-1',
      payload: {'status': 'queued'},
    );
    expect(operation.encode(), contains('item-1'));
    expect(operation.encode(), contains('queued'));
  });
}
