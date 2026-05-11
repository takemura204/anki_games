import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../model/question_learning_stats.dart';
import '../providers/learning_history_provider.dart';

final FutureProvider<Map<String, QuestionLearningStats>>
    itPassLearningStatsProvider =
    FutureProvider.autoDispose<Map<String, QuestionLearningStats>>((ref) {
  return ref.read(learningHistoryRepositoryProvider).loadAll();
});
