import 'dart:math' as math;

import 'package:app_block_puzzle/features/quiz/view_model/word_range_view_model.dart';
import 'package:app_block_puzzle/router/modal_sheet_router.dart';
import 'package:core/config/extensions/context_extension.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/features/quiz/view_model/quiz_view_model.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:core/utils/service/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
        LevelFilter.toeic600 => t.quiz.levelToeic600,
        LevelFilter.toeic700 => t.quiz.levelToeic700,
        LevelFilter.toeic800 => t.quiz.levelToeic800,
        LevelFilter.toeic900 => t.quiz.levelToeic900,
        LevelFilter.debug => t.quiz.levelDebug,
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final quizState = ref.watch(quizViewModelProvider);
    final quizNotifier = ref.read(quizViewModelProvider.notifier);
    final isPremium = ref.watch(
      premiumViewModelProvider.select(
        (s) => s.asData?.value.isPremium ?? false,
      ),
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
      backgroundColor: colorScheme.surface,
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
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: () =>
                        ref.read(wordRangeViewModelProvider.notifier).goBack(),
                  ),
                  Expanded(
                    child: Text(
                      appBarTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.labelLarge.copyWith(
                        letterSpacing: 2,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      size: 22,
                    ),
                    onPressed: () => _showWordListSheet(context, colorScheme),
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
                          colorScheme: colorScheme,
                        ),
                      )
                    else
                      SizedBox(
                        height: 160,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (dashboardBreakdown != null) ...[
                      _SectionLabel(
                        label: t.quiz.sectionMasteryFilter,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 8),
                      _StageGroupCards(
                        breakdown: dashboardBreakdown,
                        selectedGroup: quizState.selectedStageGroup,
                        colorScheme: colorScheme,
                        onSelect: quizNotifier.setStageGroupFilter,
                      ),
                      const SizedBox(height: 16),
                      _SectionLabel(
                        label: t.quiz.sectionThemeFilter,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 8),
                      _ThemeGrid(
                        themeWordCounts: quizState.themeWordCounts,
                        selectedThemes: quizState.selectedThemes,
                        colorScheme: colorScheme,
                        isPremium: isPremium,
                        onToggle: quizNotifier.toggleThemeFilter,
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (quizState.topWorstWords.isNotEmpty &&
                        quizState.selectedStageGroup != 1) ...[
                      _WeakWordsCard(
                        words: quizState.topWorstWords.take(3).toList(),
                        colorScheme: colorScheme,
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
                        style: AppTextStyle.labelLarge.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: canStart
                          ? () => ref
                              .read(wordRangeViewModelProvider.notifier)
                              .startGame(singleLevel: singleLevel)
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
                        canStart
                            ? t.quiz
                                .startButton(count: quizState.filteredWordCount)
                            : t.quiz.startLabel,
                        style: AppTextStyle.titleLarge,
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

  void _showWordListSheet(BuildContext context, ColorScheme colorScheme) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WordListSheet(colorScheme: colorScheme),
    );
  }
}

// ── Hero ダッシュボード（大ドーナツ + ステータスピル） ──────────────

class _HeroDashboard extends StatelessWidget {
  const _HeroDashboard({
    required this.breakdown,
    required this.total,
    required this.colorScheme,
  });

  final MasteryBreakdown breakdown;
  final int total;
  final ColorScheme colorScheme;

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
                  holeColor: colorScheme.surface,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$perfectPct%',
                    style: AppTextStyle.headlineMedium.copyWith(
                      color: colorScheme.onSurface,
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
  const _SectionLabel({required this.label, required this.colorScheme});

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyle.labelSmall.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}

// ── ステージグループカード（横スクロール5枚） ─────────────────────

class _StageGroupCards extends StatelessWidget {
  const _StageGroupCards({
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
        width: 76,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.14)
              : colorScheme.onSurface.withValues(alpha: 0.05),
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
              style: AppTextStyle.labelSmall.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$count語',
              style: AppTextStyle.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── テーマグリッド（5列） ─────────────────────────────────────────

class _ThemeGrid extends ConsumerWidget {
  const _ThemeGrid({
    required this.themeWordCounts,
    required this.selectedThemes,
    required this.colorScheme,
    required this.isPremium,
    required this.onToggle,
  });

  final Map<String, int> themeWordCounts;
  final Set<String> selectedThemes;
  final ColorScheme colorScheme;
  final bool isPremium;
  final void Function(String) onToggle;

  static String _label(String theme) => switch (theme) {
        'frequent' => '頻出',
        'nature' => '自然',
        'animal' => '動物',
        'body' => '体・健康',
        'food' => '食べ物',
        'home' => '家・生活',
        'clothing' => '服装',
        'sports' => 'スポーツ',
        'time' => '時間',
        'place' => '場所',
        'people' => '人',
        'occupation' => '仕事',
        'country' => '国・地域',
        'communication' => '会話',
        'media' => 'メディア',
        'mind' => '気持ち',
        'movement' => '移動',
        'action' => '行動',
        'object' => 'モノ',
        'tech' => '技術',
        'abstract' => '概念',
        'event' => '行事',
        'creation' => '制作',
        'transport' => '乗り物',
        'finance' => 'お金',
        'business' => 'ビジネス',
        'management' => '管理',
        'grammar' => '文法',
        'adj_emotion' => '感情',
        'adj_nationality' => '国籍',
        'adj_quality' => '品質',
        'adj_quantity' => '数量',
        'adj_size' => '大きさ',
        'adj_state' => '状態',
        'adj_weather' => '天気',
        'adverb' => '副詞',
        'adverb_phrase' => '副詞句',
        'conjunction' => '接続詞',
        'phrase' => 'フレーズ',
        'preposition' => '前置詞',
        'pronoun' => '代名詞',
        'interjection' => '感嘆詞',
        'unit' => '単位',
        _ => theme,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = <({String theme, int count})>[];
    final frequentCount = themeWordCounts['frequent'] ?? 0;
    if (frequentCount > 0) {
      entries.add((theme: 'frequent', count: frequentCount));
    }
    final others = themeWordCounts.entries
        .where((e) => e.key != 'frequent' && e.value > 0)
        .map((e) => (theme: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    entries.addAll(others);

    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      children: [
        for (final entry in entries)
          _ThemeCard(
            label: _label(entry.theme),
            count: entry.count,
            isSelected: isPremium && selectedThemes.contains(entry.theme),
            isLocked: !isPremium,
            colorScheme: colorScheme,
            onTap: !isPremium
                ? () => ref.read(modalSheetRouterProvider).showPaywall()
                : () => onToggle(entry.theme),
          ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.isLocked,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final bool isLocked;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.14)
                    : colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? accent.withValues(alpha: 0.55)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.captionSmall.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? accent
                          : colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count語',
                    style: AppTextStyle.labelMedium.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.8),
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

// ── 苦手ワードカード（TOP3） ──────────────────────────────────────

class _WeakWordsCard extends StatelessWidget {
  const _WeakWordsCard({required this.words, required this.colorScheme});

  final List<WordEntry> words;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.04),
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
                  style: AppTextStyle.labelSmall.copyWith(
                    letterSpacing: 0.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < words.length; i++) ...[
              if (i > 0) ...[
                Divider(
                  height: 1,
                  color: colorScheme.onSurface.withValues(alpha: 0.07),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      words[i].word.en,
                      style: AppTextStyle.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    words[i].word.ja,
                    style: AppTextStyle.labelLarge.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
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
  const _WordListSheet({required this.colorScheme});

  final ColorScheme colorScheme;

  static const _stageFilters = [-1, 0, 1, 2, 3, 4];

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
          color: colorScheme.surface,
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
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
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
                    style: AppTextStyle.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
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
                style: AppTextStyle.bodySmall
                    .copyWith(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: t.quiz.searchHint,
                  hintStyle: AppTextStyle.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: colorScheme.onSurface.withValues(alpha: 0.06),
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
                      colorScheme: colorScheme,
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
                        style: AppTextStyle.bodySmall.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (_, i) => _WordRow(
                        entry: filtered[i],
                        colorScheme: colorScheme,
                        onStatusTap: () => _showStatusMenu(
                          context,
                          filtered[i],
                          colorScheme,
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
    ColorScheme colorScheme,
    QuizViewModel notifier,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surface,
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
                  style: AppTextStyle.titleMedium.copyWith(
                    color: colorScheme.onSurface,
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
                    style: AppTextStyle.bodyMedium.copyWith(
                      fontWeight: entry.stage == stage
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: entry.stage == stage
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: colorScheme.primary,
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
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final ColorScheme colorScheme;
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
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.15))
              : colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (color == Colors.transparent
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : color.withValues(alpha: 0.5))
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyle.labelMedium.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            color: isSelected
                ? (color == Colors.transparent ? colorScheme.primary : color)
                : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.entry,
    required this.colorScheme,
    required this.onStatusTap,
  });

  final WordEntry entry;
  final ColorScheme colorScheme;
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
              style: AppTextStyle.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.word.ja,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.labelLarge.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.volume_up_rounded,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.45),
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
                style: AppTextStyle.labelSmall.copyWith(
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
