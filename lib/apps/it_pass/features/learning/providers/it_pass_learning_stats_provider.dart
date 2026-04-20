import 'package:anki_games/apps/it_pass/features/learning/model/question_learning_stats.dart';
import 'package:anki_games/apps/it_pass/features/learning/repository/local_learning_history_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final AutoDisposeFutureProvider<Map<String, QuestionLearningStats>>
    itPassLearningStatsProvider =
    FutureProvider.autoDispose<Map<String, QuestionLearningStats>>((ref) {
  return LocalLearningHistoryRepository().loadAll();
});
