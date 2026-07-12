import 'dart:ui';

import 'package:core/components/admob_glass.dart';
import 'package:core/components/buttons.dart';
import 'package:core/components/category_filter_section.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/components/modal_handle.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/filter/model/quiz_order_mode.dart';
import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:core/features/exam_quiz/model/exam_meta.dart';
import 'package:core/features/exam_quiz/purchase/view/paywall_sheet.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../view_model/filter_view_model.dart';

part 'widgets/apply_button.dart';
part 'widgets/era_chip.dart';
part 'widgets/era_section.dart';
part 'widgets/filter_section_card.dart';
part 'widgets/glass_expansion_tile.dart';
part 'widgets/header.dart';
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
            border: Border(top: BorderSide(color: context.appColors.border1)),
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
    final isPremium =
        ref.watch(premiumViewModelProvider).asData?.value.isPremium ?? false;
    final allSystemsSelected =
        filterState.selectedSystems.length == filterState.categoryTree.length;
    final noSystemsSelected = filterState.selectedSystems.isEmpty;

    return Column(
      children: [
        const ModalHandle(),
        _Header(onClose: () => Navigator.of(context).pop(false)),
        const Gap(AppSpacing.sm),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            children: [
              const Gap(AppSpacing.sm),
              //試験回
              _FilterSectionCard(
                child: _EraSection(
                  selectedEraIds: filterState.selectedEraIds,
                  isPremium: isPremium,
                  availableExamList: filterState.availableExamList,
                  freeEraIds: filterState.freeEraIds,
                  onToggle: vm.toggleEra,
                  onSelectAll: vm.selectAllEras,
                  onClearAll: vm.clearAllEras,
                  onLockedTap: () => showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    constraints: const BoxConstraints(),
                    builder: (_) => const PaywallSheet(),
                  ),
                  hasEraSelected: filterState.hasEraSelected,
                ),
              ),
              const Gap(AppSpacing.sm),
              //分野
              _FilterSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(
                      '分野',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TextLinkButton(
                            label: 'すべて選択',
                            onTap: allSystemsSelected
                                ? null
                                : vm.selectAllSystems,
                            active: allSystemsSelected,
                          ),
                          const Gap(AppSpacing.xs),
                          _TextLinkButton(
                            label: 'すべて解除',
                            onTap: noSystemsSelected
                                ? null
                                : vm.clearAllSystems,
                          ),
                        ],
                      ),
                    ),
                    _SystemMajorSection(
                      selectedSystems: filterState.selectedSystems,
                      selectedMajors: filterState.selectedMajors,
                      expandedSystems: filterState.expandedSystems,
                      categoryTree: filterState.categoryTree,
                      onSystemToggle: vm.toggleSystem,
                      onMajorToggle: vm.toggleMajor,
                      onExpansionToggle: vm.toggleSystemExpansion,
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.sm),
              //学習レベル
              _FilterSectionCard(
                child: _LearningLevelFilterSection(
                  selected: filterState.selectedLearningLevels,
                  onToggle: vm.toggleLearningLevel,
                  onSelectAll: vm.selectAllLearningLevels,
                  onClearAll: vm.clearLearningLevels,
                ),
              ),
              const Gap(AppSpacing.sm),
              //出題順
              _FilterSectionCard(
                child: _OrderModeSection(
                  mode: filterState.quizOrderMode,
                  onChanged: vm.setQuizOrderMode,
                ),
              ),
              const Gap(AppSpacing.md),
              const AdmobNativeGlass(),
              const Gap(AppSpacing.lg),
            ],
          ),
        ),
        const Gap(5),
        _MatchCountBar(
          matchCount: filterState.matchCount,
          hasEraSelected: filterState.hasEraSelected,
        ),
        _ApplyButton(
          canApply: filterState.canApply,
          isApplying: filterState.isApplying,
          buttonText: filterState.buttonText,
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
