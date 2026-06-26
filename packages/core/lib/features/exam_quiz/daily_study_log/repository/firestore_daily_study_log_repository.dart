import 'package:cloud_firestore/cloud_firestore.dart';

import '../../daily_study_log/model/daily_study_log.dart';

class FirestoreDailyStudyLogRepository {
  FirestoreDailyStudyLogRepository({required this.uid});

  final String uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dailyStudyLogs');

  Future<void> addStudySeconds(String dateKey, int seconds) async {
    await _col.doc(dateKey).set({
      'date': dateKey,
      'studySeconds': FieldValue.increment(seconds),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> incrementNewReview(String dateKey) async {
    await _col.doc(dateKey).set({
      'date': dateKey,
      'newReviewCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> incrementAnswered(
    String dateKey, {
    required bool isCorrect,
  }) async {
    await _col.doc(dateKey).set({
      'date': dateKey,
      'answeredCount': FieldValue.increment(1),
      if (isCorrect) 'correctCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> batchSave(List<DailyStudyLog> logs) async {
    if (logs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final log in logs) {
      batch.set(
        _col.doc(log.date),
        {
          ...log.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<List<DailyStudyLog>> loadAll() async {
    final snap = await _col.get();
    return snap.docs.map((d) => DailyStudyLog.fromJson(d.data())).toList();
  }
}
