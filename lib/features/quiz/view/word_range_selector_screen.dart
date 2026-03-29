import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/view/block_puzzle_screen.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/block_puzzle/view_model/theme_view_model.dart';
import 'package:mono_games/features/purchase/view/paywall_bottom_sheet.dart';
import 'package:mono_games/features/purchase/view_model/premium_view_model.dart';
import 'package:mono_games/features/quiz/view_model/quiz_view_model.dart';
import 'package:mono_games/i18n/translations.g.dart';
import 'package:mono_games/until/service/tts_service.dart';

/// 英単語 × パズルモード開始前の WordMode ハブ画面。
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
    Future<void>.microtask(
      () => ref.read(quizViewModelProvider.notifier).loadMasteryStats(),
    );
  }

  String _levelLabel(LevelFilter level) => switch (level) {
        LevelFilter.eiken5 => t.quiz.levelEiken5,
        LevelFilter.eiken4 => t.quiz.levelEiken4,
        LevelFilter.eiken3 => t.quiz.levelEiken3,
        LevelFilter.eikenPre2 => t.quiz.levelEikenPre2,
        LevelFilter.eiken2 => t.quiz.levelEiken2,
        LevelFilter.toiecBasic => t.quiz.levelToiecBasic,
        LevelFilter.debug => t.quiz.levelDebug,
      };

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeViewModelProvider);
    final colors = theme.colorsFor(Theme.of(context).brightness);
    final quizState = ref.watch(quizViewModelProvider);
    final quizNotifier = ref.read(quizViewModelProvider.notifier);
    final isPremium = ref.watch(
      premiumViewModelProvider.select((s) => s.valueOrNull?.isPremium ?? false),
    );

    final breakdowns = quizState.masteryBreakdowns;

    final singleLevel = quizState.selectedLevels.length == 1
        ? quizState.selectedLevels.first
        : null;
    final dashboardBreakdown = singleLevel != null
        ? breakdowns[singleLevel.name]
        : breakdowns[MasteryRangeFilter.all.name];
    final dashboardTotal = dashboardBreakdown == null
        ? 0
        : dashboardBreakdown.newWords +
            dashboardBreakdown.hard +
            dashboardBreakdown.learning +
            dashboardBreakdown.good +
            dashboardBreakdown.perfect;

    final appBarTitle = singleLevel != null
        ? _levelLabel(singleLevel).toUpperCase()
        : t.quiz.wordModeTitle;

    final canStart = quizState.filteredWordCount >= 3;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
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
                      appBarTitle,
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
                  IconButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colors.onSurface.withValues(alpha: 0.6),
                      size: 22,
                    ),
                    onPressed: () => _showWordListSheet(context, colors),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    if (dashboardBreakdown != null)
                      Center(
                        child: _HeroDashboard(
                          breakdown: dashboardBreakdown,
                          total: dashboardTotal,
                          colors: colors,
                        ),
                      )
                    else
                      SizedBox(
                        height: 160,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: colors.accent,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (dashboardBreakdown != null) ...[
                      _SectionLabel(
                        label: t.quiz.sectionMasteryFilter,
                        colors: colors,
                      ),
                      const SizedBox(height: 8),
                      _StageGroupCards(
                        breakdown: dashboardBreakdown,
                        selectedGroup: quizState.selectedStageGroup,
                        colors: colors,
                        onSelect: quizNotifier.setStageGroupFilter,
                      ),
                      const SizedBox(height: 16),
                      _SectionLabel(
                        label: t.quiz.sectionThemeFilter,
                        colors: colors,
                      ),
                      const SizedBox(height: 8),
                      _ThemeCards(
                        themeWordCounts: quizState.themeWordCounts,
                        selectedThemes: quizState.selectedThemes,
                        colors: colors,
                        isPremium: isPremium,
                        onToggle: quizNotifier.toggleThemeFilter,
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (quizState.topWorstWords.isNotEmpty &&
                        quizState.selectedStageGroup != 1) ...[
                      _WeakWordsCard(
                        words: quizState.topWorstWords.take(3).toList(),
                        colors: colors,
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  if (!canStart)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        quizState.selectedStageGroup == 1
                            ? t.quiz.noWeakWords
                            : t.quiz.tooFewWords,
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
                          ? () async {
                              ref
                                  .read(quizViewModelProvider.notifier)
                                  .resetSession();
                              ref
                                  .read(blockPuzzleViewModelProvider.notifier)
                                  .startQuizMode();
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const BlockPuzzleScreen(),
                                ),
                              );
                              if (context.mounted) {
                                await ref
                                    .read(quizViewModelProvider.notifier)
                                    .loadMasteryStats();
                              }
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
                            ? t.quiz
                                .startButton(count: quizState.filteredWordCount)
                            : t.quiz.startLabel,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
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

  void _showWordListSheet(BuildContext context, GameThemeColors colors) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WordListSheet(colors: colors),
    );
  }
}

// ── Hero ダッシュボード（大ドーナツ + ステータスピル） ──────────────

class _HeroDashboard extends StatelessWidget {
  const _HeroDashboard({
    required this.breakdown,
    required this.total,
    required this.colors,
  });

  final MasteryBreakdown breakdown;
  final int total;
  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final perfectPct =
        total > 0 ? ((breakdown.perfect / total) * 100).round() : 0;

    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(160, 160),
                painter: _PieChartPainter(
                  breakdown: breakdown,
                  total: total,
                  holeColor: colors.surface,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$perfectPct%',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 円グラフ CustomPainter ────────────────────────────────────────

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter({
    required this.breakdown,
    required this.total,
    required this.holeColor,
  });

  final MasteryBreakdown breakdown;
  final int total;
  final Color holeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final slices = [
      (breakdown.newWords / total, Colors.grey),
      (breakdown.hard / total, Colors.red.shade400),
      (breakdown.learning / total, Colors.orange.shade400),
      (breakdown.good / total, Colors.blue.shade400),
      (breakdown.perfect / total, Colors.green.shade400),
    ];

    var startAngle = -math.pi / 2;
    for (final (fraction, color) in slices) {
      if (fraction == 0) {
        continue;
      }
      final sweepAngle = fraction * 2 * math.pi;
      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      startAngle += sweepAngle;
    }

    canvas.drawCircle(
      center,
      radius * 0.70,
      Paint()..color = holeColor,
    );
  }

  @override
  bool shouldRepaint(_PieChartPainter old) =>
      old.breakdown != breakdown || old.total != total;
}

// ── セクションラベル ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.colors});

  final String label;
  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: colors.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

// ── ステージグループカード（横スクロール5枚） ─────────────────────

class _StageGroupCards extends StatelessWidget {
  const _StageGroupCards({
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
      height: 84,
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
        width: 76,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.14)
              : colors.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
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
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : colors.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$count語',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
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

// ── ジャンルカード（Wrap） ────────────────────────────────────────

class _ThemeCards extends StatelessWidget {
  const _ThemeCards({
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
              width: 76,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.14)
                    : colors.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
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
                    size: 18,
                    color: isSelected
                        ? accentColor
                        : colors.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
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
            if (isLocked)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.lock_rounded, size: 12, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 苦手ワードカード（TOP3） ──────────────────────────────────────

class _WeakWordsCard extends StatelessWidget {
  const _WeakWordsCard({required this.words, required this.colors});

  final List<WordEntry> words;
  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 13,
                  color: Colors.red.shade400,
                ),
                const SizedBox(width: 5),
                Text(
                  t.quiz.rankingWorst,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < words.length; i++) ...[
              if (i > 0) ...[
                Divider(
                  height: 1,
                  color: colors.onSurface.withValues(alpha: 0.07),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      words[i].word.en,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    words[i].word.ja,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              if (i < words.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 単語一覧ボトムシート ──────────────────────────────────────────

class _WordListSheet extends HookConsumerWidget {
  const _WordListSheet({required this.colors});

  final GameThemeColors colors;

  static const _stageFilters = [-1, 0, 1, 2, 3, 4]; // -1 = 全て

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizState = ref.watch(quizViewModelProvider);
    final quizNotifier = ref.read(quizViewModelProvider.notifier);
    final searchController = useTextEditingController();
    final searchText = useState('');
    final selectedStage = useState(-1);

    useEffect(() {
      searchController.addListener(() {
        searchText.value = searchController.text;
      });
      return null;
    }, [searchController]);

    final filtered = quizState.wordEntries.where((e) {
      final matchSearch = searchText.value.isEmpty ||
          e.word.en.toLowerCase().contains(searchText.value.toLowerCase()) ||
          e.word.ja.contains(searchText.value);
      final matchStage = selectedStage.value == -1 ||
          _stageToGroup(e.stage) == selectedStage.value;
      return matchSearch && matchStage;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    t.quiz.wordListTitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: searchController,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: colors.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: t.quiz.searchHint,
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: colors.onSurface.withValues(alpha: 0.35),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: colors.onSurface.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: colors.onSurface.withValues(alpha: 0.06),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final stage in _stageFilters) ...[
                    _StageTab(
                      label: _stageTabLabel(stage),
                      isSelected: selectedStage.value == stage,
                      color: _stageColor(stage),
                      colors: colors,
                      onTap: () => selectedStage.value = stage,
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        t.quiz.noWordsFound,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: colors.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (_, i) => _WordRow(
                        entry: filtered[i],
                        colors: colors,
                        onStatusTap: () => _showStatusMenu(
                          context,
                          filtered[i],
                          colors,
                          quizNotifier,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  int _stageToGroup(int stage) => stage;

  String _stageTabLabel(int stage) => switch (stage) {
        -1 => t.quiz.levelAll,
        0 => t.quiz.masteryNew,
        1 => t.quiz.masteryHard,
        2 => t.quiz.masteryLearning,
        3 => t.quiz.masteryGood,
        _ => t.quiz.masteryPerfect,
      };

  Color _stageColor(int stage) => switch (stage) {
        -1 => Colors.transparent,
        0 => Colors.grey,
        1 => Colors.red.shade400,
        2 => Colors.orange.shade400,
        3 => Colors.blue.shade400,
        _ => Colors.green.shade400,
      };

  void _showStatusMenu(
    BuildContext context,
    WordEntry entry,
    GameThemeColors colors,
    QuizViewModel notifier,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  entry.word.en,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
              for (final (stage, label, color) in [
                (0, t.quiz.masteryNew, Colors.grey),
                (1, t.quiz.masteryHard, Colors.red.shade400),
                (2, t.quiz.masteryLearning, Colors.orange.shade400),
                (3, t.quiz.masteryGood, Colors.blue.shade400),
                (4, t.quiz.masteryPerfect, Colors.green.shade400),
              ])
                ListTile(
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: entry.stage == stage
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: colors.onSurface,
                    ),
                  ),
                  trailing: entry.stage == stage
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: colors.accent,
                        )
                      : null,
                  onTap: () async {
                    Navigator.of(context).pop();
                    await notifier.updateWordStage(entry.word.id, stage);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageTab extends StatelessWidget {
  const _StageTab({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final GameThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (color == Colors.transparent
                  ? colors.accent.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.15))
              : colors.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (color == Colors.transparent
                    ? colors.accent.withValues(alpha: 0.5)
                    : color.withValues(alpha: 0.5))
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            color: isSelected
                ? (color == Colors.transparent ? colors.accent : color)
                : colors.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.entry,
    required this.colors,
    required this.onStatusTap,
  });

  final WordEntry entry;
  final GameThemeColors colors;
  final VoidCallback onStatusTap;

  Color get _stageColor => switch (entry.stage) {
        0 => Colors.grey,
        1 => Colors.red.shade400,
        2 => Colors.orange.shade400,
        3 => Colors.blue.shade400,
        _ => Colors.green.shade400,
      };

  String get _stageLabel => switch (entry.stage) {
        0 => t.quiz.masteryNew,
        1 => t.quiz.masteryHard,
        2 => t.quiz.masteryLearning,
        3 => t.quiz.masteryGood,
        _ => t.quiz.masteryPerfect,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              entry.word.en,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.word.ja,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: colors.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.volume_up_rounded,
              size: 18,
              color: colors.onSurface.withValues(alpha: 0.45),
            ),
            onPressed: () => TtsService.instance.speak(entry.word.en),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onStatusTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _stageColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _stageLabel,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _stageColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
