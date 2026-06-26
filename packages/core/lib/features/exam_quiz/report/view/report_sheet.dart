import 'dart:ui';

import 'package:core/components/buttons.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/components/modal_handle.dart';
import 'package:core/config/brand/it_pass_color_scheme.dart';
import 'package:core/config/extensions/context_extension.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:core/features/exam_quiz/purchase/view/paywall_sheet.dart';
import 'package:core/features/exam_quiz/report/model/progress_dashboard_data.dart';
import 'package:core/features/exam_quiz/report/model/report_stats.dart';
import 'package:core/features/exam_quiz/report/view_model/progress_dashboard_provider.dart';
import 'package:core/features/exam_quiz/report/view_model/report_stats_provider.dart';
import 'package:core/features/exam_quiz/streak/view/streak_banner.dart';
import 'package:core/features/exam_quiz/streak/view_model/streak_view_model.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';

part 'widgets/report_header.dart';
part 'widgets/report_paywall_banner.dart';
part 'widgets/report_progress_section.dart';
part 'widgets/report_stats_grid.dart';

class ReportSheet extends ConsumerWidget {
  const ReportSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statsAsync = ref.watch(reportStatsProvider);
    final streak = ref.watch(streakViewModelProvider);
    final isPremium = ref.watch(
      premiumViewModelProvider.select(
        (AsyncValue<PremiumState> s) => s.asData?.value.isPremium ?? false,
      ),
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: screenHeight * 0.85,
          decoration: BoxDecoration(
            color: context.appColors.surfaceSheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: context.appColors.border1)),
          ),
          child: Column(
            children: [
              const ModalHandle(),
              _ReportHeader(onClose: () => Navigator.of(context).pop()),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      children: [
                        const Gap(AppSpacing.sm),
                        StreakSummaryCard(streak: streak),
                        const Gap(AppSpacing.lg),
                        if (isPremium) ...[
                          statsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white54,
                              ),
                            ),
                            error: (_, _) => const SizedBox.shrink(),
                            data: (stats) => _StatsGrid(stats: stats),
                          ),
                          const Gap(AppSpacing.lg),
                          const _ProgressSection(),
                          const Gap(AppSpacing.lg),
                        ] else
                          const _LockedContentPreview(),
                      ],
                    ),
                    if (!isPremium)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _PaywallBanner(
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            constraints: const BoxConstraints(),
                            builder: (_) => const PaywallSheet(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
