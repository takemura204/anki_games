import 'package:core/features/purchase/model/plan_type.dart';

/// ユーザーが選択した学習期間の目標。
enum StudyGoal {
  withinOneMonth,
  withinThreeMonths,
  withinHalfYear,
  overOneYear;

  /// ユーザー向け表示ラベル。
  String get label => switch (this) {
        StudyGoal.withinOneMonth => '1ヶ月以内',
        StudyGoal.withinThreeMonths => '3ヶ月以内',
        StudyGoal.withinHalfYear => '半年以内',
        StudyGoal.overOneYear => '1年以上',
      };

  /// 学習期間に応じた推奨プラン。
  ///
  /// 短期（1/3ヶ月）は月額、長期（半年以上）は買い切りを推奨。
  PlanType get recommendedPlan => switch (this) {
        StudyGoal.withinOneMonth => PlanType.monthly,
        StudyGoal.withinThreeMonths => PlanType.monthly,
        StudyGoal.withinHalfYear => PlanType.lifetime,
        StudyGoal.overOneYear => PlanType.lifetime,
      };
}
