import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/admob/admob_banner.dart';
import 'package:mono_games/features/block_puzzle/model/board.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/background_effect_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/board_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/countdown_overlay.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/game_over_overlay.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/piece_tray_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/quest_success_overlay.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/score_hud_widget.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/time_attack_result_overlay.dart';
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
    final isTimeAttackMode = gameState.isTimeAttackMode;
    final isTimeAttackComplete = gameState.isTimeAttackComplete;
    final isTimeAttackCountingDown = gameState.isTimeAttackCountingDown;
    final colors = theme.colorsFor(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // 背景エフェクト
            Positioned.fill(
              child: BackgroundEffectWidget(theme: theme),
            ),
            // メインゲームレイアウト
            Column(
              children: [
                const SizedBox(height: 8),
                // 上部バー: 戻るボタン + モード表示 + 設定ボタン
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
                      if (isTimeAttackMode)
                        Text(
                          'TIME ATTACK',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        )
                      else if (isQuestMode)
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
                // タイムアタック: タイマーバー
                if (isTimeAttackMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _TimerBar(
                      fraction:
                          gameState.timeAttackRemainingSeconds / 90,
                      color: colors.accent,
                      trackColor: colors.emptyCellFill,
                    ),
                  ),
                // スコアHUD
                ScoreHudWidget(theme: theme),
                const SizedBox(height: 24),
                // ボード + ピーストレイ
                //
                // DragTargetがboardSize + dragExtension (cellSize * 10) の高さを持つ。
                // AdmobBannerが表示されるとExpandedが縮小しDragTargetがPieceTrayに
                // 重なりポインタイベントがブロックされる問題を防ぐため、
                // ボードとピーストレイを同じExpanded内に配置し、
                // LayoutBuilderで幅・高さ両方からcellSizeを算出する。
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, expandedConstraints) {
                      // board(8セル) + dragExtension(2セル) + pieceTray(4セル) = 14セル
                      const boardPadding = 20.0;
                      const totalCellsForHeight = 14.0;
                      final fromWidth =
                          (expandedConstraints.maxWidth -
                                  boardPadding * 2) /
                              Board.size;
                      final fromHeight =
                          expandedConstraints.maxHeight /
                              totalCellsForHeight;
                      final cellSize = fromWidth < fromHeight
                          ? fromWidth
                          : fromHeight;

                      return Column(
                        children: [
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
                          PieceTrayWidget(
                            cellSize: cellSize,
                            theme: theme,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // バナー広告
                const AdmobBanner(),
              ],
            ),
            // ゲームオーバーオーバーレイ（タイムアタックは別オーバーレイで処理）
            if (isGameOver && !isTimeAttackMode)
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
                ),
              ),
            // タイムアタック終了オーバーレイ（タイムアップ or 手詰まり）
            if (isTimeAttackComplete)
              Positioned.fill(
                child: TimeAttackResultOverlay(theme: theme),
              ),
            // タイムアタック開始前カウントダウンオーバーレイ
            if (isTimeAttackCountingDown)
              Positioned.fill(
                child: CountdownOverlay(theme: theme),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimerBar extends StatelessWidget {
  const _TimerBar({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: fraction.clamp(0.0, 1.0),
        minHeight: 4,
        backgroundColor: trackColor,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
