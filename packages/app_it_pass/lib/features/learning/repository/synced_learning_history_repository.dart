import 'dart:async';

import '../model/question_learning_stats.dart';
import 'firestore_learning_history_repository.dart';
import 'learning_history_repository.dart';
import 'local_learning_history_repository.dart';

class SyncedLearningHistoryRepository implements LearningHistoryRepository {
  SyncedLearningHistoryRepository({
    required this.local,
    required this.remote,
  });

  final LocalLearningHistoryRepository local;
  final FirestoreLearningHistoryRepository remote;

  @override
  Future<Map<String, QuestionLearningStats>> loadAll() => local.loadAll();

  @override
  Future<void> recordAnswer({
    required String eraId,
    required int no,
    required bool isCorrect,
    required DateTime at,
    required String selectedLabel,
  }) async {
    await local.recordAnswer(
      eraId: eraId,
      no: no,
      isCorrect: isCorrect,
      at: at,
      selectedLabel: selectedLabel,
    );
    unawaited(
      remote
          .recordAnswer(
            eraId: eraId,
            no: no,
            isCorrect: isCorrect,
            at: at,
            selectedLabel: selectedLabel,
          )
          .catchError((_) {}),
    );
  }

  @override
  Future<void> unmarkMastered(String eraId, int no) async {
    await local.unmarkMastered(eraId, no);
    unawaited(remote.unmarkMastered(eraId, no).catchError((_) {}));
  }

  @override
  Future<void> markMastered(String eraId, int no) async {
    await local.markMastered(eraId, no);
    unawaited(remote.markMastered(eraId, no).catchError((_) {}));
  }

  @override
  Future<Set<String>> loadMastered() => local.loadMastered();

  @override
  Future<void> deleteAll() async {
    await local.deleteAll();
    unawaited(remote.deleteAll().catchError((_) {}));
  }
}
