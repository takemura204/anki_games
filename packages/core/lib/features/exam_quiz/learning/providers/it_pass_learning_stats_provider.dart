import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/question_learning_stats.dart';
import '../providers/learning_history_provider.dart';

part 'it_pass_learning_stats_provider.g.dart';

@riverpod
Future<Map<String, QuestionLearningStats>> itPassLearningStats(
  Ref ref,
) async {
  final repo = await ref.watch(learningHistoryRepositoryProvider.future);
  return repo.loadAll();
}
