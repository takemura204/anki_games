import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/block_puzzle/view_model/theme_view_model.dart';
import 'package:mono_games/features/purchase/view/paywall_bottom_sheet.dart';
import 'package:mono_games/features/purchase/view_model/premium_view_model.dart';
import 'package:mono_games/features/quiz/view_model/quiz_view_model.dart';
import 'package:mono_games/i18n/translations.g.dart';

/// 資格レベルカードをタップしたときに表示するクイズ開始ボトムシート。
///
/// ユーザーが Start をタップした場合は `true` を返す。
Future<bool> showQuizStartBottomSheet(
  BuildContext context,
  LevelFilter level,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuizStartBottomSheet(level: level),
  );
  return result ?? false;
}

class _QuizStartBottomSheet extends ConsumerWidget {
  const _QuizStartBottomSheet({required this.level});

  final LevelFilter level;

  String _levelLabel() => switch (level) {
        LevelFilter.eiken5 => t.quiz.levelEiken5,
        LevelFilter.eiken4 => t.quiz.levelEiken4,
        LevelFilter.eiken3 => t.quiz.levelEiken3,
        LevelFilter.eikenPre2 => t.quiz.levelEikenPre2,
        LevelFilter.eiken2 => t.quiz.levelEiken2,
        LevelFilter.toiecBasic => t.quiz.levelToiecBasic,
        LevelFilter.debug => t.quiz.levelDebug,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameTheme = ref.watch(themeViewModelProvider);
    final colors = gameTheme.colorsFor(Theme.of(context).brightness);
    final quizState = ref.watch(quizViewModelProvider);
    final quizNotifier = ref.read(quizViewModelProvider.notifier);
    final isPremium = ref.watch(
      premiumViewModelProvider.select((s) => s.valueOrNull?.isPremium ?? false),
    );

    final canStart = quizState.filteredWordCount >= 3;
    final breakdown = quizState.masteryBreakdowns[level.name];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
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
                color: colors.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _levelLabel().toUpperCase(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t.quiz.sectionMasteryFilter.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: colors.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          if (breakdown != null)
            _StageFilter(
              breakdown: breakdown,
              selectedGroup: quizState.selectedStageGroup,
              colors: colors,
              onSelect: quizNotifier.setStageGroupFilter,
            ),
          const SizedBox(height: 16),
          Text(
            t.quiz.sectionThemeFilter.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: colors.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          _ThemeFilter(
            themeWordCounts: quizState.themeWordCounts,
            selectedThemes: quizState.selectedThemes,
            colors: colors,
            isPremium: isPremium,
            onToggle: quizNotifier.toggleThemeFilter,
          ),
          const SizedBox(height: 20),
          if (!canStart) ...[
            Text(
              quizState.selectedStageGroup == 1
                  ? t.quiz.noWeakWords
                  : t.quiz.tooFewWords,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: colors.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextButton(
            onPressed: canStart
                ? () {
                    quizNotifier.resetSession();
                    ref
                        .read(blockPuzzleViewModelProvider.notifier)
                        .startQuizMode();
                    Navigator.of(context).pop(true);
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
              canStart
                  ? t.quiz.startButton(count: quizState.filteredWordCount)
                  : t.quiz.startLabel,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 習熟度フィルター（横スクロール） ────────────────────────────────

class _StageFilter extends StatelessWidget {
  const _StageFilter({
    required this.breakdown,
    required this.selectedGroup,
    required this.colors,
    required this.onSelect,
  });

  final MasteryBreakdown breakdown;
  final int? selectedGroup;
  final GameThemeColors colors;
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
      height: 76,
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
                    ? colors.accent
                    : entry.color,
                isSelected: selectedGroup == entry.group,
                colors: colors,
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
    required this.colors,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final GameThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 68,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.14)
              : colors.onSurface.withValues(alpha: 0.05),
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
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : colors.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count語',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? colors.onSurface
                    : colors.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ジャンルフィルター（Wrap） ────────────────────────────────────

class _ThemeFilter extends StatelessWidget {
  const _ThemeFilter({
    required this.themeWordCounts,
    required this.selectedThemes,
    required this.colors,
    required this.isPremium,
    required this.onToggle,
  });

  final Map<String, int> themeWordCounts;
  final Set<String> selectedThemes;
  final GameThemeColors colors;
  final bool isPremium;
  final ValueChanged<String> onToggle;

  static const _themes = [
    'frequent',
    'nature',
    'daily',
    'people',
    'place',
    'action',
    'mind',
    'quality',
    'school',
    'general',
  ];

  String _label(String theme) => switch (theme) {
        'frequent' => t.quiz.themeFrequent,
        'nature' => t.quiz.themeNature,
        'daily' => t.quiz.themeDaily,
        'people' => t.quiz.themePeople,
        'place' => t.quiz.themePlace,
        'action' => t.quiz.themeAction,
        'mind' => t.quiz.themeMind,
        'quality' => t.quiz.themeQuality,
        'school' => t.quiz.themeSchool,
        _ => t.quiz.themeGeneral,
      };

  IconData _icon(String theme) => switch (theme) {
        'frequent' => Icons.star_rounded,
        'nature' => Icons.park_rounded,
        'daily' => Icons.home_rounded,
        'people' => Icons.people_rounded,
        'place' => Icons.location_on_rounded,
        'action' => Icons.directions_run_rounded,
        'mind' => Icons.favorite_rounded,
        'quality' => Icons.auto_awesome_rounded,
        'school' => Icons.school_rounded,
        _ => Icons.category_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedThemes.isEmpty;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final theme in _themes)
          _ThemeCard(
            label: _label(theme),
            icon: _icon(theme),
            count: themeWordCounts[theme] ?? 0,
            isSelected: !isPremium
                ? theme == 'frequent'
                : allSelected || selectedThemes.contains(theme),
            isLocked: theme != 'frequent' && !isPremium,
            colors: colors,
            onTap: !isPremium && theme == 'frequent'
                ? null
                : () => onToggle(theme),
          ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.isLocked,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool isSelected;
  final bool isLocked;
  final GameThemeColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = colors.accent;
    return GestureDetector(
      onTap: isLocked ? () => showPaywallBottomSheet(context) : onTap,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 68,
              height: 72,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.14)
                    : colors.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.55)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? accentColor
                        : colors.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? accentColor
                          : colors.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count語',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? colors.onSurface
                          : colors.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.lock_rounded, size: 10, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
