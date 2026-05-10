import 'dart:ui';

import 'package:app_it_pass/components/glass_widget.dart';
import 'package:app_it_pass/components/modal_handle.dart';
import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:app_it_pass/features/learning/model/learning_level.dart';
import 'package:app_it_pass/features/report/view_model/progress_dashboard_provider.dart';
import 'package:app_it_pass/features/report/view_model/report_stats_provider.dart';
import 'package:app_it_pass/features/streak/view/streak_banner.dart';
import 'package:app_it_pass/features/streak/view_model/streak_view_model.dart';
import 'package:core/config/extensions/context_extension.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../model/progress_dashboard_data.dart';
import '../model/report_stats.dart';

part 'widgets/report_header.dart';
part 'widgets/report_stats_grid.dart';
part 'widgets/report_progress_section.dart';

class ReportSheet extends ConsumerWidget {
  const ReportSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statsAsync = ref.watch(reportStatsProvider);
    final streak = ref.watch(streakViewModelProvider);

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
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  children: [
                    const Gap(AppSpacing.sm),
                    StreakSummaryCard(streak: streak),
                    const Gap(AppSpacing.md),
                    statsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white54),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (stats) => _StatsGrid(stats: stats),
                    ),
                    const Gap(AppSpacing.lg),
                    const _ProgressSection(),
                    const Gap(AppSpacing.lg),
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
