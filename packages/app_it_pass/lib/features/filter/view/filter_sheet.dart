import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../learning/model/learning_level.dart';
import '../../quiz/model/exam_meta.dart';
import '../../quiz/view_model/quiz_view_model.dart';
import '../model/quiz_order_mode.dart';
import '../view_model/filter_view_model.dart';

part 'widgets/apply_button.dart';
part 'widgets/era_chip.dart';
part 'widgets/era_section.dart';
part 'widgets/filter_handle.dart';
part 'widgets/filter_header.dart';
part 'widgets/filter_section_card.dart';
part 'widgets/glass_expansion_tile.dart';
part 'widgets/learning_level_filter_section.dart';
part 'widgets/major_section.dart';
part 'widgets/match_count_bar.dart';
part 'widgets/order_mode_section.dart';
part 'widgets/section_label.dart';
part 'widgets/system_section.dart';

Future<void> showQuizFilterSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final applied = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FilterSheet(
      onApplied: () => Navigator.of(ctx).pop(true),
      onClose: () => Navigator.of(ctx).pop(false),
    ),
  );

  if (applied == true) {
    ref.invalidate(quizViewModelProvider);
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet({
    required this.onApplied,
    required this.onClose,
  });

  final VoidCallback onApplied;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final asyncState = ref.watch(filterViewModelProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: screenHeight * 0.88,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0B2B).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          child: asyncState.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
            error: (e, _) => Center(
              child: Text(
                e.toString(),
                style: const TextStyle(color: Colors.white54),
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
        const _FilterHandle(),
        _FilterHeader(onClose: onClose),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            children: [
              _FilterSectionCard(
                child: _OrderModeSection(
                  mode: filterState.quizOrderMode,
                  onChanged: vm.setQuizOrderMode,
                ),
              ),
              const Gap(12),
              _FilterSectionCard(
                child: _LearningLevelFilterSection(
                  selected: filterState.selectedLearningLevels,
                  onToggle: vm.toggleLearningLevel,
                  onClear: vm.clearLearningLevels,
                ),
              ),
              const Gap(12),
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
              const Gap(12),
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
              const Gap(12),
              _FilterSectionCard(
                child: _EraSection(
                  selectedEraIds: filterState.selectedEraIds,
                  onToggle: vm.toggleEra,
                  onSelectAll: vm.selectAllEras,
                  onClearAll: vm.clearAllEras,
                  canApply: filterState.canApply,
                ),
              ),
              const Gap(24),
            ],
          ),
        ),
        if (filterState.applyValidationMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFBBF24),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    filterState.applyValidationMessage!,
                    style: TextStyle(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.95),
                      fontSize: 13,
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
              onApplied();
            }
          },
        ),
      ],
    );
  }
}
