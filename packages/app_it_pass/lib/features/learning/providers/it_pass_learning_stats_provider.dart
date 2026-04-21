import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../model/question_learning_stats.dart';
import '../repository/local_learning_history_repository.dart';

final FutureProvider<Map<String, QuestionLearningStats>>
    itPassLearningStatsProvider =
    FutureProvider.autoDispose<Map<String, QuestionLearningStats>>((ref) {
  return LocalLearningHistoryRepository().loadAll();
});
