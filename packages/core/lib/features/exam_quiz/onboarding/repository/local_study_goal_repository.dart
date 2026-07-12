import 'package:core/features/exam_quiz/onboarding/model/study_goal.dart';
import 'package:core/features/purchase/model/plan_type.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyStudyGoal = 'study_goal_v1';

/// ユーザーの学習期間目標を SharedPreferences に永続化するリポジトリ。
class LocalStudyGoalRepository {
  Future<StudyGoal?> getGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyStudyGoal);
    if (raw == null) return null;
    return StudyGoal.values.where((g) => g.name == raw).firstOrNull;
  }

  Future<void> saveGoal(StudyGoal goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStudyGoal, goal.name);
  }
}

/// [LocalStudyGoalRepository] のプロバイダ。
final studyGoalRepositoryProvider = Provider<LocalStudyGoalRepository>(
  (_) => LocalStudyGoalRepository(),
);

/// 保存済みの学習目標から推奨プランを返すプロバイダ。
///
/// 未設定の場合は [PlanType.monthly] をデフォルトとして返す。
final recommendedPlanProvider = FutureProvider<PlanType>((ref) async {
  final goal = await ref.watch(studyGoalRepositoryProvider).getGoal();
  return goal?.recommendedPlan ?? PlanType.monthly;
});
