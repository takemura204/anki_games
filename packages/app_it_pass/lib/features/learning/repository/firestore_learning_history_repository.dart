import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(uid);

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
    await _historyCol.doc(key).set({
      'correctCount': FieldValue.increment(isCorrect ? 1 : 0),
      'wrongCount': FieldValue.increment(isCorrect ? 0 : 1),
      'lastAnsweredAt': at.toIso8601String(),
      'lastWasCorrect': isCorrect,
      'lastSelectedLabel': selectedLabel,
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
    batch.delete(_userDoc);
    await batch.commit();
  }

  @override
  Future<void> markMastered(String eraId, int no) async {
    final key = LocalLearningHistoryRepository.storageKey(eraId, no);
    await _userDoc.set({
      'masteredKeys': FieldValue.arrayUnion([key]),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> unmarkMastered(String eraId, int no) async {
    final key = LocalLearningHistoryRepository.storageKey(eraId, no);
    await _userDoc.set({
      'masteredKeys': FieldValue.arrayRemove([key]),
    }, SetOptions(merge: true));
  }

  @override
  Future<Set<String>> loadMastered() async {
    final snap = await _userDoc.get();
    if (!snap.exists) return {};
    final raw = snap.data()?['masteredKeys'];
    if (raw == null) return {};
    return List<String>.from(raw as List).toSet();
  }

  Future<void> _updateMasteredKeys(List<String> keys) async {
    await _userDoc.set({'masteredKeys': keys}, SetOptions(merge: true));
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
      LocalLearningHistoryRepository local) async {
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

    final remoteMastered = await loadMastered();
    final localMastered = await local.loadMastered();
    final union = {...localMastered, ...remoteMastered};
    if (union.length > localMastered.length) {
      await local.saveAllMastered(union);
    }
    if (union.length > remoteMastered.length) {
      await _updateMasteredKeys(union.toList());
    }
  }
}
