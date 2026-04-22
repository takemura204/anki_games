import 'dart:ui';
import 'package:app_it_pass/components/glass_widget.dart';
import 'package:app_it_pass/components/modal_handle.dart';
import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../learning/model/learning_level.dart';
import '../../quiz/model/exam_meta.dart';
import '../model/quiz_order_mode.dart';
import '../view_model/filter_view_model.dart';

part 'widgets/apply_button.dart';
part 'widgets/era_chip.dart';
part 'widgets/era_section.dart';
part 'widgets/header.dart';
part 'widgets/filter_section_card.dart';
part 'widgets/glass_expansion_tile.dart';
part 'widgets/learning_level_filter_section.dart';
part 'widgets/major_section.dart';
part 'widgets/match_count_bar.dart';
part 'widgets/order_mode_section.dart';
part 'widgets/section_label.dart';
part 'widgets/system_section.dart';

class FilterSheet extends ConsumerWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final asyncState = ref.watch(filterViewModelProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: screenHeight * 0.85,
          decoration: BoxDecoration(
            color: context.appColors.surfaceSheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: context.appColors.border1),
            ),
          ),
          child: asyncState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
            error: (e, _) => Center(
              child: Text(
                e.toString(),
                style: AppTextStyle.bodyMedium.copyWith(color: Colors.white54),
              ),
            ),
            data: (filterState) => _buildContent(context, ref, filterState),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    FilterState filterState,
  ) {
    final vm = ref.read(filterViewModelProvider.notifier);

    return Column(
      children: [
        const ModalHandle(),
        _Header(onClose: () => Navigator.of(context).pop(false)),
        const Gap(AppSpacing.sm),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              const Gap(AppSpacing.sm),
              _FilterSectionCard(
                child: _OrderModeSection(
                  mode: filterState.quizOrderMode,
                  onChanged: vm.setQuizOrderMode,
                ),
              ),
              const Gap(AppSpacing.sm),
              _FilterSectionCard(
                child: _LearningLevelFilterSection(
                  selected: filterState.selectedLearningLevels,
                  onToggle: vm.toggleLearningLevel,
                  onClear: vm.clearLearningLevels,
                ),
              ),
              const Gap(AppSpacing.sm),
              _FilterSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('分野（系統）'),
                    _SystemSection(
                      selectedSystems: filterState.selectedSystems,
                      onToggle: vm.toggleSystem,
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.sm),
              _FilterSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('中分類'),
                    _MajorSection(
                      selectedSystems: filterState.selectedSystems,
                      selectedMajors: filterState.selectedMajors,
                      expandedSystems: filterState.expandedSystems,
                      onToggle: vm.toggleMajor,
                      onExpansionToggle: vm.toggleSystemExpansion,
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.sm),
              _FilterSectionCard(
                child: _EraSection(
                  selectedEraIds: filterState.selectedEraIds,
                  onToggle: vm.toggleEra,
                  onSelectAll: vm.selectAllEras,
                  onClearAll: vm.clearAllEras,
                  canApply: filterState.canApply,
                ),
              ),
              const Gap(AppSpacing.lg),
            ],
          ),
        ),
        if (filterState.applyValidationMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: AppSpacing.md + 4,
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: Text(
                    filterState.applyValidationMessage!,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColors.warning.withValues(alpha: 0.95),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Gap(5),
        _MatchCountBar(
          matchCount: filterState.matchCount,
          canApply: filterState.canApply,
        ),
        _ApplyButton(
          canApply: filterState.canApply,
          isApplying: filterState.isApplying,
          onTap: () async {
            final ok = await vm.apply();
            if (ok) {
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            }
          },
        ),
      ],
    );
  }
}
