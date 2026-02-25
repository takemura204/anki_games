import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/block_puzzle/model/board.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/background_effect_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/board_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/game_over_overlay.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/piece_tray_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/quest_success_overlay.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/score_hud_widget.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/block_puzzle/view_model/theme_view_model.dart';
import 'package:mono_games/features/settings/view/settings_dialog.dart';

/// Noir Mindパズルゲームのメイン画面。
///
/// ナビゲーション前に呼び出し側がゲームモードを初期化すること。
class BlockPuzzleScreen extends ConsumerWidget {
  /// Noir Mind画面を作成する。
  const BlockPuzzleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeViewModelProvider);
    final gameState = ref.watch(blockPuzzleViewModelProvider);
    final isGameOver = gameState.isGameOver;
    final isQuestComplete = gameState.isQuestComplete;
    final isQuestMode = gameState.isQuestMode;
    final colors = theme.colorsFor(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const boardPadding = 20.0;
            final cellSize = (constraints.maxWidth - boardPadding * 2) / Board.size;

            return Stack(
              children: [
                // 背景エフェクト
                Positioned.fill(
                  child: BackgroundEffectWidget(theme: theme),
                ),
                // メインゲームレイアウト
                Column(
                  children: [
                    const SizedBox(height: 8),
                    // 上部バー: 戻るボタン + レベル表示 + 設定ボタン
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: colors.onSurface.withValues(alpha: 0.6),
                              size: 20,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          if (isQuestMode)
                            Text(
                              'LEVEL ${gameState.questLevel}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.settings_outlined,
                              color: colors.onSurface.withValues(alpha: 0.6),
                              size: 22,
                            ),
                            onPressed: () => showGameSettingsDialog(context),
                          ),
                        ],
                      ),
                    ),
                    // スコアHUD
                    ScoreHudWidget(theme: theme),
                    const SizedBox(height: 24),
                    // ボード
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: boardPadding,
                          ),
                          child: BoardWidget(
                            cellSize: cellSize,
                            theme: theme,
                          ),
                        ),
                      ),
                    ),
                    // ピーストレイ
                    Padding(
                      padding: const EdgeInsets.only(bottom: boardPadding),
                      child: PieceTrayWidget(
                        cellSize: cellSize,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                // ゲームオーバーオーバーレイ
                if (isGameOver)
                  Positioned.fill(
                    child: GameOverOverlay(theme: theme),
                  ),
                // クエスト達成オーバーレイ
                if (isQuestComplete)
                  Positioned.fill(
                    child: QuestSuccessOverlay(
                      theme: theme,
                      level: gameState.questLevel,
                      score: gameState.score,
                      targetScore: gameState.targetScore,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
