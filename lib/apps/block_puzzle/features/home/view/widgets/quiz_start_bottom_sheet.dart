import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:anki_games/common/config/extensions/context_extension.dart';
import 'package:anki_games/common/config/styles/app_text_style.dart';
import 'package:anki_games/common/features/quiz/view_model/quiz_view_model.dart';
import 'package:anki_games/common/i18n/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QuizStartSheet extends ConsumerWidget {
  const QuizStartSheet({required this.level, super.key});

  final LevelFilter level;

  String _levelLabel() => switch (level) {
        LevelFilter.eiken5 => t.quiz.levelEiken5,
        LevelFilter.eiken4 => t.quiz.levelEiken4,
        LevelFilter.eiken3 => t.quiz.levelEiken3,
        LevelFilter.eikenPre2 => t.quiz.levelEikenPre2,
        LevelFilter.eiken2 => t.quiz.levelEiken2,
        LevelFilter.toeic600 => t.quiz.levelToeic600,
        LevelFilter.toeic700 => t.quiz.levelToeic700,
        LevelFilter.toeic800 => t.quiz.levelToeic800,
        LevelFilter.toeic900 => t.quiz.levelToeic900,
        LevelFilter.debug => t.quiz.levelDebug,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = context.colorScheme;
    final quizState = ref.watch(quizViewModelProvider);
    final quizNotifier = ref.read(quizViewModelProvider.notifier);

    final canStart = quizState.filteredWordCount >= 3;
    final breakdown = quizState.masteryBreakdowns[level.name];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _levelLabel().toUpperCase(),
            style: AppTextStyle.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t.quiz.sectionMasteryFilter.toUpperCase(),
            style: AppTextStyle.labelSmall.copyWith(
              letterSpacing: 1,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (breakdown != null)
            _StageCards(
              breakdown: breakdown,
              selectedGroup: quizState.selectedStageGroup,
              colorScheme: colorScheme,
              onSelect: quizNotifier.setStageGroupFilter,
            ),
          const SizedBox(height: 16),
          Text(
            t.quiz.sectionQuestionOrder.toUpperCase(),
            style: AppTextStyle.labelSmall.copyWith(
              letterSpacing: 1,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _QuizOrderRow(
            selected: quizState.quizOrderMode,
            colorScheme: colorScheme,
            onSelect: quizNotifier.setQuizOrderMode,
          ),
          const SizedBox(height: 20),
          if (!canStart) ...[
            Text(
              quizState.selectedStageGroup == 1
                  ? t.quiz.noWeakWords
                  : t.quiz.tooFewWords,
              textAlign: TextAlign.center,
              style: AppTextStyle.labelMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextButton(
            onPressed: canStart
                ? () async {
                    final hasSaved =
                        ref
                            .read(blockPuzzleViewModelProvider)
                            .levelHasSavedGame[level.name] ??
                        false;

                    if (hasSaved) {
                      final shouldContinue = await showDialog<bool>(
                        context: context,
                        builder: (_) => _ContinueDialog(colorScheme: colorScheme),
                      );
                      if (shouldContinue == null) {
                        return;
                      }
                      if (!shouldContinue) {
                        await ref
                            .read(blockPuzzleViewModelProvider.notifier)
                            .resetAndStartQuizMode(level);
                      } else {
                        ref
                            .read(blockPuzzleViewModelProvider.notifier)
                            .startQuizMode(level);
                      }
                    } else {
                      ref
                          .read(blockPuzzleViewModelProvider.notifier)
                          .startQuizMode(level);
                    }
                    quizNotifier.resetSession();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop(true);
                  }
                : null,
            style: TextButton.styleFrom(
              backgroundColor: canStart
                  ? colorScheme.primary
                  : colorScheme.primary.withValues(alpha: 0.3),
              foregroundColor: colorScheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: Text(
              t.quiz.startLabel,
              style: AppTextStyle.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageCards extends StatelessWidget {
  const _StageCards({
    required this.breakdown,
    required this.selectedGroup,
    required this.colorScheme,
    required this.onSelect,
  });

  final MasteryBreakdown breakdown;
  final int? selectedGroup;
  final ColorScheme colorScheme;
  final ValueChanged<int?> onSelect;

  static const _groups = <({int? group, Color color})>[
    (group: null, color: Colors.transparent),
    (group: 0, color: Colors.grey),
    (group: 1, color: Color(0xFFEF5350)),
    (group: 2, color: Color(0xFFFFA726)),
    (group: 3, color: Color(0xFF42A5F5)),
    (group: 4, color: Color(0xFF66BB6A)),
  ];

  String _label(int? group) => switch (group) {
        null => t.quiz.filterAll,
        0 => t.quiz.masteryNew,
        1 => t.quiz.masteryHard,
        2 => t.quiz.masteryLearning,
        3 => t.quiz.masteryGood,
        _ => t.quiz.masteryPerfect,
      };

  int _count(int? group) => switch (group) {
        null => breakdown.newWords +
            breakdown.hard +
            breakdown.learning +
            breakdown.good +
            breakdown.perfect,
        0 => breakdown.newWords,
        1 => breakdown.hard,
        2 => breakdown.learning,
        3 => breakdown.good,
        _ => breakdown.perfect,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in _groups)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StageCard(
                label: _label(entry.group),
                count: _count(entry.group),
                color: entry.color == Colors.transparent
                    ? colorScheme.primary
                    : entry.color,
                isSelected: selectedGroup == entry.group,
                colorScheme: colorScheme,
                onTap: () => onSelect(
                  selectedGroup == entry.group ? null : entry.group,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 60,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.14)
              : colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? color.withValues(alpha: 0.55) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyle.labelSmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count語',
              style: AppTextStyle.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizOrderRow extends StatelessWidget {
  const _QuizOrderRow({
    required this.selected,
    required this.colorScheme,
    required this.onSelect,
  });

  final QuizOrderMode selected;
  final ColorScheme colorScheme;
  final Future<void> Function(QuizOrderMode mode) onSelect;

  static const _modes = <QuizOrderMode>[
    QuizOrderMode.auto,
    QuizOrderMode.masteryLowToHigh,
    QuizOrderMode.masteryHighToLow,
  ];

  String _label(QuizOrderMode mode) => switch (mode) {
        QuizOrderMode.auto => t.quiz.orderAuto,
        QuizOrderMode.masteryLowToHigh => t.quiz.orderMasteryLowFirst,
        QuizOrderMode.masteryHighToLow => t.quiz.orderMasteryHighFirst,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          for (final mode in _modes)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelect(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: selected == mode
                          ? colorScheme.primary.withValues(alpha: 0.14)
                          : colorScheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected == mode
                            ? colorScheme.primary.withValues(alpha: 0.55)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _label(mode),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.labelSmall.copyWith(
                          fontWeight: selected == mode
                              ? FontWeight.w700
                              : FontWeight.w500,
                          height: 1.2,
                          color: selected == mode
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContinueDialog extends StatelessWidget {
  const _ContinueDialog({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        '途中のデータがあります',
        style: AppTextStyle.titleMedium.copyWith(color: colorScheme.onSurface),
      ),
      content: Text(
        'このレベルの途中ゲームデータが保存されています。続きから始めますか？',
        style: AppTextStyle.bodySmall.copyWith(
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            '最初から',
            style: AppTextStyle.bodySmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          ),
          child: Text(
            '続きから',
            style: AppTextStyle.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
