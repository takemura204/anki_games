part of '../home_screen.dart';

class _LevelCards extends ConsumerWidget {
  const _LevelCards({
    required this.colors,
    required this.masteryBreakdowns,
  });

  final GameThemeColors colors;
  final Map<String, MasteryBreakdown> masteryBreakdowns;

  static List<LevelFilter> get _levels => kDebugMode
      ? LevelFilter.values
      : LevelFilter.values
          .where((l) => l != LevelFilter.debug)
          .toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(quizViewModelProvider.notifier);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        for (final level in _levels)
          _LevelCard(
            level: level,
            breakdown: masteryBreakdowns[level.name],
            colors: colors,
            onTap: () async {
              await notifier.setLevelFilter(level);
              if (!context.mounted) {
                return;
              }
              final shouldStart =
                  await showQuizStartBottomSheet(context, level);
              if (!shouldStart || !context.mounted) {
                return;
              }
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BlockPuzzleScreen(),
                ),
              );
              if (context.mounted) {
                await notifier.loadMasteryStats();
              }
            },
          ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.breakdown,
    required this.colors,
    required this.onTap,
  });

  final LevelFilter level;
  final MasteryBreakdown? breakdown;
  final GameThemeColors colors;
  final VoidCallback onTap;

  String _label() => switch (level) {
        LevelFilter.eiken5 => '英検 5級',
        LevelFilter.eiken4 => '英検 4級',
        LevelFilter.eiken3 => '英検 3級',
        LevelFilter.eikenPre2 => '英検 準2級',
        LevelFilter.eiken2 => '英検 2級',
        LevelFilter.toiecBasic => 'TOEIC',
        LevelFilter.debug => '[DEV]',
      };

  double _progress() {
    final bd = breakdown;
    if (bd == null) {
      return 0;
    }
    final total =
        bd.newWords + bd.hard + bd.learning + bd.good + bd.perfect;
    if (total == 0) {
      return 0;
    }
    return (bd.good + bd.perfect) / total;
  }

  @override
  Widget build(BuildContext context) {
    final pct = _progress();
    final pctLabel = '${(pct * 100).toStringAsFixed(0)}%';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _label(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: colors.onSurface.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              pctLabel,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
