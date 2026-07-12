import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/leitner_box.dart';
import '../model/question_learning_stats.dart';
import 'learning_history_repository.dart';
import 'local_learning_history_repository.dart';

const _lastSyncedUidKey = 'last_synced_uid';

class FirestoreLearningHistoryRepository implements LearningHistoryRepository {
  FirestoreLearningHistoryRepository({required this.uid});

  final String uid;

  CollectionReference<Map<String, dynamic>> get _historyCol =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('learningHistory');

  @override
  Future<Map<String, QuestionLearningStats>> loadAll() async {
    final snap = await _historyCol.get();
    return {
      for (final doc in snap.docs)
        doc.id: QuestionLearningStats.fromJson(doc.data()),
    };
  }

  @override
  Future<void> recordAnswer({
    required String eraId,
    required int no,
    required bool isCorrect,
    required DateTime at,
    required String selectedLabel,
  }) async {
    final key = LocalLearningHistoryRepository.storageKey(eraId, no);
    final doc = _historyCol.doc(key);
    final snap = await doc.get();
    final prev = snap.exists
        ? QuestionLearningStats.fromJson(snap.data()!)
        : const QuestionLearningStats();
    final nextBox = advance(
      prev.box ?? (prev.correctCount + prev.wrongCount == 0 ? null : boxFromLegacyStats(prev)),
      isCorrect: isCorrect,
    );
    await doc.set({
      'correctCount': FieldValue.increment(isCorrect ? 1 : 0),
      'wrongCount': FieldValue.increment(isCorrect ? 0 : 1),
      'lastAnsweredAt': at.toIso8601String(),
      'lastWasCorrect': isCorrect,
      'lastSelectedLabel': selectedLabel,
      'box': nextBox,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> batchWrite(Map<String, QuestionLearningStats> map) async {
    if (map.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final entry in map.entries) {
      batch.set(
        _historyCol.doc(entry.key),
        {
          ...entry.value.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  @override
  Future<void> deleteAll() async {
    final snap = await _historyCol.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// uid 変化時のみ双方向マージを実行する。
  Future<void> runInitialSyncIfNeeded({
    required LocalLearningHistoryRepository local,
    required String uid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_lastSyncedUidKey) == uid) return;

    await _runBidirectionalMerge(local);

    await prefs.setString(_lastSyncedUidKey, uid);
  }

  Future<void> _runBidirectionalMerge(
    LocalLearningHistoryRepository local,
  ) async {
    final remoteHistory = await loadAll();
    final localHistory = await local.loadAll();

    final merged = Map<String, QuestionLearningStats>.from(localHistory);
    final toUpload = <String, QuestionLearningStats>{};

    for (final entry in remoteHistory.entries) {
      final l = localHistory[entry.key];
      final remoteNewer = l == null ||
          (entry.value.lastAnsweredAt ?? DateTime(0))
              .isAfter(l.lastAnsweredAt ?? DateTime(0));
      if (remoteNewer) merged[entry.key] = entry.value;
    }

    for (final entry in merged.entries) {
      final r = remoteHistory[entry.key];
      final localNewer = r == null ||
          (entry.value.lastAnsweredAt ?? DateTime(0))
              .isAfter(r.lastAnsweredAt ?? DateTime(0));
      if (localNewer) toUpload[entry.key] = entry.value;
    }

    await local.saveAll(merged);
    await batchWrite(toUpload);
  }
}
