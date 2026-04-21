part of '../home_screen.dart';

class _LevelCards extends ConsumerWidget {
  const _LevelCards({required this.masteryBreakdowns});

  final Map<String, MasteryBreakdown> masteryBreakdowns;

  static List<LevelFilter> get _levels => kDebugMode
      ? LevelFilter.values
      : LevelFilter.values.where((l) => l != LevelFilter.debug).toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeVm = ref.read(homeViewModelProvider.notifier);
    final puzzleState = ref.watch(blockPuzzleViewModelProvider);
    final colorScheme = context.colorScheme;

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      children: [
        for (final level in _levels)
          _LevelCard(
            level: level,
            breakdown: masteryBreakdowns[level.name],
            highScore: puzzleState.levelHighScores[level.name] ?? 0,
            hasSavedGame:
                puzzleState.levelHasSavedGame[level.name] ?? false,
            colorScheme: colorScheme,
            onTap: () => homeVm.onLevelCardTap(level),
          ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.breakdown,
    required this.highScore,
    required this.hasSavedGame,
    required this.colorScheme,
    required this.onTap,
  });

  final LevelFilter level;
  final MasteryBreakdown? breakdown;
  final int highScore;
  final bool hasSavedGame;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  String _sublabel() => switch (level) {
        LevelFilter.eiken5 ||
        LevelFilter.eiken4 ||
        LevelFilter.eiken3 ||
        LevelFilter.eikenPre2 ||
        LevelFilter.eiken2 =>
          '英検',
        LevelFilter.toeic600 ||
        LevelFilter.toeic700 ||
        LevelFilter.toeic800 ||
        LevelFilter.toeic900 =>
          'TOEIC',
        LevelFilter.debug => '[DEV]',
      };

  String _mainLabel() => switch (level) {
        LevelFilter.eiken5 => '5級',
        LevelFilter.eiken4 => '4級',
        LevelFilter.eiken3 => '3級',
        LevelFilter.eikenPre2 => '準2級',
        LevelFilter.eiken2 => '2級',
        LevelFilter.toeic600 => '600',
        LevelFilter.toeic700 => '700',
        LevelFilter.toeic800 => '800',
        LevelFilter.toeic900 => '900',
        LevelFilter.debug => 'Debug',
      };

  double _progress() {
    final bd = breakdown;
    if (bd == null) {
      return 0;
    }
    final total = bd.newWords + bd.hard + bd.learning + bd.good + bd.perfect;
    if (total == 0) {
      return 0;
    }
    return (bd.good + bd.perfect) / total;
  }

  String _formatScore(int score) {
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}k';
    }
    return ' $score';
  }

  @override
  Widget build(BuildContext context) {
    final pct = _progress();
    final pctLabel = '${(pct * 100).toStringAsFixed(0)}%';
    final sublabel = _sublabel();
    final mainLabel = _mainLabel();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            if (sublabel.isNotEmpty)
              Text(
                sublabel,
                style: AppTextStyle.captionSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: colorScheme.onSurface,
                ),
              ),
            Text(
              mainLabel,
              style: AppTextStyle.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (highScore > 0)
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                const Gap(1),
                Text(
                  highScore > 0 ? _formatScore(highScore) : '--',
                  style: AppTextStyle.captionSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor:
                        colorScheme.onSurface.withValues(alpha: 0.1),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    minHeight: 13,
                  ),
                ),
                Text(
                  pctLabel,
                  style: AppTextStyle.captionSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
