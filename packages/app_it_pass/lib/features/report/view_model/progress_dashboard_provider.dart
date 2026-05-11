import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../learning/model/learning_level.dart';
import '../../learning/providers/learning_history_provider.dart';
import '../../learning/repository/local_learning_history_repository.dart'
    show LocalLearningHistoryRepository;
import '../../quiz/model/exam_meta.dart';
import '../../quiz/repository/quiz_repository.dart';
import '../model/progress_dashboard_data.dart';

final progressDashboardProvider =
    FutureProvider<ProgressDashboardData>((ref) async {
  final learningStats = await ref.read(learningHistoryRepositoryProvider).loadAll();
  final repo = QuizRepository();

  final results = await Future.wait(
    ExamMeta.all.map((m) async {
      try {
        final questions = await repo.loadEra(m.eraId);
        return (meta: m, questions: questions);
      } on Object {
        return (meta: m, questions: const <dynamic>[]);
      }
    }),
  );

  final allCounts = <LearningLevel, int>{};
  final systemCounts = <String, Map<LearningLevel, int>>{
    for (final key in ExamMeta.categoryTree.keys) key: {},
  };
  final eraCounts = <String, Map<LearningLevel, int>>{};

  for (final result in results) {
    for (final q in result.questions) {
      final key = LocalLearningHistoryRepository.storageKey(q.eraId, q.no);
      final level = LearningLevel.fromStats(learningStats[key]);

      if (result.meta.group != ExamGroup.sample) {
        allCounts[level] = (allCounts[level] ?? 0) + 1;
        final bucket = systemCounts[q.system];
        if (bucket != null) {
          bucket[level] = (bucket[level] ?? 0) + 1;
        }
      } else {
        eraCounts.putIfAbsent(result.meta.eraId, () => {});
        eraCounts[result.meta.eraId]![level] =
            (eraCounts[result.meta.eraId]![level] ?? 0) + 1;
      }
    }
  }

  SystemProgress makeProgress(Map<LearningLevel, int> counts) {
    final total = counts.values.fold(0, (a, b) => a + b);
    return SystemProgress(counts: counts, total: total);
  }

  return ProgressDashboardData(
    all: makeProgress(allCounts),
    bySystem: {
      for (final entry in systemCounts.entries)
        entry.key: makeProgress(entry.value),
    },
    byEra: {
      for (final entry in eraCounts.entries)
        entry.key: makeProgress(entry.value),
    },
  );
});
