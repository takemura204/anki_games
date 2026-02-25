import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/view/block_puzzle_screen.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/theme_block_preview.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/block_puzzle/view_model/quest_progress_view_model.dart';
import 'package:mono_games/features/block_puzzle/view_model/theme_view_model.dart';
import 'package:mono_games/features/settings/view/settings_dialog.dart';
import 'package:mono_games/i18n/translations.g.dart';

part 'widgets/mode_card.dart';

/// The home screen displaying a list of available games.
class HomeScreen extends ConsumerWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questState = ref.watch(questProgressViewModelProvider);
    final highScore = ref.watch(
      blockPuzzleViewModelProvider.select((s) => s.highScore),
    );
    final gameTheme = ref.watch(themeViewModelProvider);
    final brightness = Theme.of(context).brightness;
    final colors = gameTheme.colorsFor(brightness);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // 設定ボタン（右上）
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: colors.onSurface.withValues(alpha: 0.55),
                  ),
                  onPressed: () => showHomeSettingsDialog(context),
                ),
              ),
              const Spacer(),

              ThemeBlockPreview(theme: gameTheme),
              const Gap(16),

              Text(
                t.blockPuzzle.title.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: colors.onSurface,
                ),
              ),
              const Gap(4),
              Text(
                t.blockPuzzle.subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: colors.onSurface.withValues(alpha: 0.45),
                ),
              ),

              const Gap(48),

              Row(
                children: [
                  _ModeCard(
                    icon: Icons.flag_rounded,
                    title: t.blockPuzzle.questMode,
                    description: t.blockPuzzle.questModeDesc,
                    badge: 'LEVEL ${questState.maxUnlockedLevel}',
                    colors: colors,
                    onTap: () {
                      final vm = ref.read(blockPuzzleViewModelProvider);
                      final hasActiveQuest =
                          vm.isQuestMode && !vm.isGameOver && !vm.isQuestComplete;
                      if (!hasActiveQuest) {
                        ref
                            .read(blockPuzzleViewModelProvider.notifier)
                            .startQuestLevel(questState.maxUnlockedLevel);
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BlockPuzzleScreen(),
                        ),
                      );
                    },
                  ),
                  const Gap(16),
                  _ModeCard(
                    icon: Icons.all_inclusive_rounded,
                    title: t.blockPuzzle.classicMode,
                    description: t.blockPuzzle.classicModeDesc,
                    badge: highScore > 0 ? 'BEST  $highScore' : 'ENDLESS',
                    colors: colors,
                    onTap: () {
                      final vm = ref.read(blockPuzzleViewModelProvider);
                      final hasActiveClassic = !vm.isQuestMode && !vm.isGameOver;
                      if (!hasActiveClassic) {
                        ref.read(blockPuzzleViewModelProvider.notifier).resetGame();
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BlockPuzzleScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
