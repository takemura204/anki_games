import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreBookmarkRepository {
  FirestoreBookmarkRepository({required this.uid});

  final String uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<void> add(String key) async {
    await _userDoc.set({
      'bookmarks': FieldValue.arrayUnion([key]),
      'bookmarksUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> remove(String key) async {
    await _userDoc.set({
      'bookmarks': FieldValue.arrayRemove([key]),
      'bookmarksUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Set<String>> load() async {
    final snap = await _userDoc.get();
    if (!snap.exists) return {};
    final raw = snap.data()?['bookmarks'];
    if (raw == null) return {};
    return List<String>.from(raw as List).toSet();
  }

  Future<void> saveAll(Set<String> keys) async {
    await _userDoc.set({
      'bookmarks': keys.toList(),
      'bookmarksUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
