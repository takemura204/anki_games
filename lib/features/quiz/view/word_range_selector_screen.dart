import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/view/block_puzzle_screen.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/block_puzzle/view_model/theme_view_model.dart';
import 'package:mono_games/features/quiz/view_model/quiz_view_model.dart';

/// 英単語 × パズルモード開始前の学習範囲選択画面。
class WordRangeSelectorScreen extends ConsumerStatefulWidget {
  /// [WordRangeSelectorScreen] を作成する。
  const WordRangeSelectorScreen({super.key});

  @override
  ConsumerState<WordRangeSelectorScreen> createState() =>
      _WordRangeSelectorScreenState();
}

class _WordRangeSelectorScreenState
    extends ConsumerState<WordRangeSelectorScreen> {
  @override
  void initState() {
    super.initState();
    // 習熟度統計をロード
    Future<void>.microtask(
      () => ref.read(quizViewModelProvider.notifier).loadMasteryStats(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeViewModelProvider);
    final colors = theme.colorsFor(Theme.of(context).brightness);
    final quizState = ref.watch(quizViewModelProvider);
    final selectedFilter = quizState.wordRangeFilter;
    final breakdowns = quizState.masteryBreakdowns;

    final overallBreakdown = breakdowns[WordRangeFilter.all.name];
    final overallTotal = overallBreakdown == null
        ? 0
        : overallBreakdown.newWords +
            overallBreakdown.hard +
            overallBreakdown.good +
            overallBreakdown.perfect;

    final selectedBreakdown = breakdowns[selectedFilter.name];
    final selectedTotal = selectedBreakdown == null
        ? 0
        : selectedBreakdown.newWords +
            selectedBreakdown.hard +
            selectedBreakdown.good +
            selectedBreakdown.perfect;
    final canStart = selectedTotal >= 3;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 上部バー ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colors.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'WORD MODE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // バランス用
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    // ── 習熟度サマリー ────────────────────────────
                    if (overallBreakdown != null) ...[
                      _MasterySummaryCard(
                        breakdown: overallBreakdown,
                        total: overallTotal,
                        colors: colors,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── フィルター選択 ────────────────────────────
                    Text(
                      '学習範囲を選ぶ',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: colors.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 習熟度系フィルター
                    _FilterSection(
                      options: const [
                        WordRangeFilter.all,
                        WordRangeFilter.weakAndNew,
                        WordRangeFilter.weakOnly,
                      ],
                      selectedFilter: selectedFilter,
                      breakdowns: breakdowns,
                      colors: colors,
                      onSelect: (f) => ref
                          .read(quizViewModelProvider.notifier)
                          .setWordRangeFilter(f),
                    ),

                    const SizedBox(height: 12),

                    // 資格系フィルター
                    Text(
                      '資格レベル',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: colors.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 8),

                    _FilterSection(
                      options: const [
                        WordRangeFilter.eiken5,
                        WordRangeFilter.eiken4,
                        WordRangeFilter.eiken3,
                        WordRangeFilter.toiecBasic,
                      ],
                      selectedFilter: selectedFilter,
                      breakdowns: breakdowns,
                      colors: colors,
                      onSelect: (f) => ref
                          .read(quizViewModelProvider.notifier)
                          .setWordRangeFilter(f),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── スタートボタン ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  if (!canStart)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'この範囲には単語が少なすぎます（3語以上必要）',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: canStart
                          ? () {
                              ref
                                  .read(blockPuzzleViewModelProvider.notifier)
                                  .startQuizMode();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const BlockPuzzleScreen(),
                                ),
                              );
                            }
                          : null,
                      style: TextButton.styleFrom(
                        backgroundColor: canStart
                            ? colors.accent
                            : colors.accent.withValues(alpha: 0.3),
                        foregroundColor: colors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        'START  $selectedTotal 語',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 習熟度サマリーカード ──────────────────────────────────────────

class _MasterySummaryCard extends StatelessWidget {
  const _MasterySummaryCard({
    required this.breakdown,
    required this.total,
    required this.colors,
  });

  final MasteryBreakdown breakdown;
  final int total;
  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final perfect = breakdown.perfect;
    final progressFraction = total > 0 ? perfect / total : 0.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 4段階カウント行
            Row(
              children: [
                _MasteryChip(
                  label: '未学習',
                  count: breakdown.newWords,
                  color: Colors.grey,
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _MasteryChip(
                  label: '苦手',
                  count: breakdown.hard,
                  color: Colors.red.shade400,
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _MasteryChip(
                  label: '得意',
                  count: breakdown.good,
                  color: Colors.blue.shade400,
                  colors: colors,
                ),
                const SizedBox(width: 8),
                _MasteryChip(
                  label: '完璧',
                  count: breakdown.perfect,
                  color: Colors.green.shade400,
                  colors: colors,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 完璧率プログレスバー
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressFraction,
                minHeight: 6,
                backgroundColor: colors.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.green.shade400,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '完璧: $perfect / $total 語',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: colors.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasteryChip extends StatelessWidget {
  const _MasteryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.colors,
  });

  final String label;
  final int count;
  final Color color;
  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── フィルター選択セクション ──────────────────────────────────────

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.options,
    required this.selectedFilter,
    required this.breakdowns,
    required this.colors,
    required this.onSelect,
  });

  final List<WordRangeFilter> options;
  final WordRangeFilter selectedFilter;
  final Map<String, MasteryBreakdown> breakdowns;
  final GameThemeColors colors;
  final ValueChanged<WordRangeFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final filter in options)
          _FilterRow(
            filter: filter,
            isSelected: filter == selectedFilter,
            breakdown: breakdowns[filter.name],
            colors: colors,
            onTap: () => onSelect(filter),
          ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.isSelected,
    required this.breakdown,
    required this.colors,
    required this.onTap,
  });

  final WordRangeFilter filter;
  final bool isSelected;
  final MasteryBreakdown? breakdown;
  final GameThemeColors colors;
  final VoidCallback onTap;

  String get _label => switch (filter) {
        WordRangeFilter.all => 'すべての単語',
        WordRangeFilter.weakAndNew => '苦手 + 未学習',
        WordRangeFilter.weakOnly => '苦手のみ',
        WordRangeFilter.eiken5 => '英検 5 級',
        WordRangeFilter.eiken4 => '英検 4 級',
        WordRangeFilter.eiken3 => '英検 3 級',
        WordRangeFilter.toiecBasic => 'TOEIC 基礎',
      };

  @override
  Widget build(BuildContext context) {
    final bd = breakdown;
    final total = bd == null
        ? 0
        : bd.newWords + bd.hard + bd.good + bd.perfect;
    final perfectFraction =
        (bd != null && total > 0) ? bd.perfect / total : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accent.withValues(alpha: 0.12)
              : colors.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.accent.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // ラジオ風インジケーター
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? colors.accent
                      : colors.onSurface.withValues(alpha: 0.3),
                  width: isSelected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // ラベル
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: colors.onSurface,
                    ),
                  ),
                  if (bd != null && total > 0) ...[
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: perfectFraction,
                        minHeight: 3,
                        backgroundColor:
                            colors.onSurface.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 語数バッジ
            Text(
              '$total 語',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: total < 3
                    ? colors.onSurface.withValues(alpha: 0.3)
                    : isSelected
                        ? colors.accent
                        : colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
