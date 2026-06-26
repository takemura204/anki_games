part of '../streak_banner.dart';

const _weekLabels = ['日', '月', '火', '水', '木', '金', '土'];

class _StreakWeekRow extends StatelessWidget {
  const _StreakWeekRow({
    required this.today,
    required this.weeklyLog,
    this.animateTodayDot = false,
  });

  final DateTime today;
  final List<DayStatus> weeklyLog;

  /// true のとき今日のドットのチェックマークをアニメーション再生する。
  final bool animateTodayDot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final d = today.subtract(Duration(days: 6 - i));
        return _StreakDayDot(
          label: _weekLabels[d.weekday % 7],
          status: weeklyLog[i],
          animateCheck: animateTodayDot && i == 6,
        );
      }),
    );
  }
}
