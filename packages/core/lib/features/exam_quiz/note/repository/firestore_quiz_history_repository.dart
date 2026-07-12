import 'package:cloud_firestore/cloud_firestore.dart';

import '../../note/model/quiz_history_record.dart';

class FirestoreQuizHistoryRepository {
  FirestoreQuizHistoryRepository({required this.uid});

  final String uid;

  static const _limit = 100;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('quizHistory');

  Future<void> saveAnswer(QuizHistoryRecord record) async {
    final docId =
        '${record.answeredAt.millisecondsSinceEpoch}_${record.eraId}_${record.no}';
    await _col.doc(docId).set(record.toJson());
  }

  Future<void> batchSave(List<QuizHistoryRecord> records) async {
    if (records.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final r in records) {
      final docId = '${r.answeredAt.millisecondsSinceEpoch}_${r.eraId}_${r.no}';
      batch.set(_col.doc(docId), r.toJson());
    }
    await batch.commit();
  }

  Future<List<QuizHistoryRecord>> loadRecent({int limit = _limit}) async {
    final snap = await _col
        .orderBy('answeredAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => QuizHistoryRecord.fromJson(d.data()))
        .toList();
  }
}
