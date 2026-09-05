import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

/// User-scoped Firestore adapter. Local Drift remains the UI source of truth;
/// the path is owner-scoped and Firestore security rules enforce authorization.
class FirestoreSyncRepository {
  FirestoreSyncRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _firestore.collection('users').doc(uid).collection('items');

  Future<void> upsertItem({
    required String uid,
    required String itemId,
    required Map<String, Object?> data,
  }) async {
    await _items(uid).doc(itemId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteItem({required String uid, required String itemId}) =>
      _items(uid).doc(itemId).delete();

  Future<List<Map<String, dynamic>>> readItems(String uid) async {
    // An empty offline cache is not an authoritative account snapshot.
    final snapshot = await _items(uid)
        .get(const GetOptions(source: Source.server));
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}

class SyncOperation {
  const SyncOperation({
    required this.type,
    required this.itemId,
    required this.payload,
  });
  final String type;
  final String itemId;
  final Map<String, Object?> payload;

  String encode() =>
      jsonEncode({'type': type, 'itemId': itemId, 'payload': payload});
}
