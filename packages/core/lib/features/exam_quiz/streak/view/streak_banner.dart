import 'package:core/components/checkmark_painter.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/streak/model/streak_data.dart';
import 'package:core/features/exam_quiz/streak/view_model/streak_view_model.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'widgets/streak_day_dot.dart';
part 'widgets/streak_flame_section.dart';
part 'widgets/streak_week_row.dart';

class StreakBannerHost extends ConsumerStatefulWidget {
  const StreakBannerHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StreakBannerHost> createState() => _StreakBannerHostState();
}

class _StreakBannerHostState extends ConsumerState<StreakBannerHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TEMP: 自動クローズ無効（確認用）。元の仕様に戻す場合は下記コメントアウト部分を参照。
    ref.listen(streakViewModelProvider, (prev, next) {
      if (next.showBanner && !(prev?.showBanner ?? false)) {
        _controller.forward(from: 0);
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          _controller.reverse().then((_) {
            if (!mounted) return;
            ref.read(streakViewModelProvider.notifier).clearBanner();
          });
        });
      }
    });

    final streak = ref.watch(streakViewModelProvider);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          widget.child,
          if (streak.currentStreak > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _slideAnim,
                child: _BannerPaddedCard(streak: streak),
              ),
            ),
        ],
      ),
    );
  }
}

/// バナー用ラッパー（ステータスバー分の上余白つき）
class _BannerPaddedCard extends StatelessWidget {
  const _BannerPaddedCard({required this.streak});

  final StreakData streak;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        topPadding + AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: StreakSummaryCard(
        streak: streak,
        animateTodayDot: streak.showBanner,
      ),
    );
  }
}

class StreakSummaryCard extends StatelessWidget {
  const StreakSummaryCard({
    super.key,
    required this.streak,
    this.animateTodayDot = false,
  });

  final StreakData streak;
  final bool animateTodayDot;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weeklyLog = streak.weeklyLog(today);

    return GlassContainer(
      cardRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _StreakFlameSection(count: streak.currentStreak),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  child: Text(
                    'あなたの連続記録',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: context.appColors.fgShade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Gap(AppSpacing.xs),
                _StreakWeekRow(
                  today: today,
                  weeklyLog: weeklyLog,
                  animateTodayDot: animateTodayDot,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
