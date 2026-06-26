import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model/user_profile.dart';

class FirestoreProfileRepository {
  DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    assert(uid != null, 'FirestoreProfileRepository requires signed-in user');
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Future<void> save(UserProfile profile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      ...profile.toJson(),
      'profileUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<({UserProfile profile, DateTime? updatedAt})> loadForMerge() async {
    final snap = await _userDoc.get();
    if (!snap.exists) {
      return (profile: const UserProfile(), updatedAt: null);
    }
    final data = snap.data()!;
    final ts = data['profileUpdatedAt'];
    final updatedAt = ts is DateTime
        ? ts
        : (ts != null ? (ts as dynamic).toDate() as DateTime : null);
    return (profile: UserProfile.fromJson(data), updatedAt: updatedAt);
  }
}
