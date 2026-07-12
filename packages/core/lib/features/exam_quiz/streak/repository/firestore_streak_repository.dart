import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/streak_data.dart';

class FirestoreStreakRepository {
  FirestoreStreakRepository({required this.uid});

  final String uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<void> save(StreakData streak) async {
    await _userDoc.set({
      'streak': {
        ...streak.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  Future<StreakData?> load() async {
    final snap = await _userDoc.get();
    if (!snap.exists) return null;
    final raw = snap.data()?['streak'];
    if (raw == null) return null;
    return StreakData.fromJson(raw as Map<String, dynamic>);
  }
}
