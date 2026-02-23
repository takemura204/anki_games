part of '../home_screen.dart';

class _HomeWidget extends ConsumerWidget {
  const _HomeWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questState = ref.watch(questProgressViewModelProvider);
    final highScore = ref.watch(
      noirMindViewModelProvider.select((s) => s.highScore),
    );
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // 設定ボタン（右上）
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                onPressed: () => showHomeSettingsDialog(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.noirMind.title.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.noirMind.subtitle,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 48),
            _ModeCard(
              icon: Icons.flag_rounded,
              title: t.noirMind.questMode,
              description: t.noirMind.questModeDesc,
              badge: 'LEVEL ${questState.maxUnlockedLevel}',
              onTap: () {
                final vm = ref.read(noirMindViewModelProvider);
                final hasActiveQuest = vm.isQuestMode &&
                    !vm.isGameOver &&
                    !vm.isQuestComplete;
                if (!hasActiveQuest) {
                  ref
                      .read(noirMindViewModelProvider.notifier)
                      .startQuestLevel(questState.maxUnlockedLevel);
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NoirMindScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _ModeCard(
              icon: Icons.all_inclusive_rounded,
              title: t.noirMind.classicMode,
              description: t.noirMind.classicModeDesc,
              badge: highScore > 0 ? 'BEST  $highScore' : 'ENDLESS',
              onTap: () {
                final vm = ref.read(noirMindViewModelProvider);
                final hasActiveClassic = !vm.isQuestMode && !vm.isGameOver;
                if (!hasActiveClassic) {
                  ref.read(noirMindViewModelProvider.notifier).resetGame();
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NoirMindScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final surfaceColor = colorScheme.surfaceContainerHighest;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                badge,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
