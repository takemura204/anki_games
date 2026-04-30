import 'package:app_it_pass/features/learning/model/learning_level.dart';

class SystemProgress {
  const SystemProgress({required this.counts, required this.total});

  static const empty = SystemProgress(counts: {}, total: 0);

  final Map<LearningLevel, int> counts;
  final int total;

  int countFor(LearningLevel level) => counts[level] ?? 0;

  double percentFor(LearningLevel level) =>
      total == 0 ? 0.0 : countFor(level) / total;
}

class ProgressDashboardData {
  const ProgressDashboardData({
    required this.all,
    required this.bySystem,
    required this.byEra,
  });

  final SystemProgress all;
  final Map<String, SystemProgress> bySystem;
  final Map<String, SystemProgress> byEra;

  SystemProgress forSystem(String system) =>
      bySystem[system] ?? SystemProgress.empty;

  SystemProgress forEra(String eraId) =>
      byEra[eraId] ?? SystemProgress.empty;
}
