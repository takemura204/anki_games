import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/noir_mind/model/board.dart';
import 'package:mono_games/features/noir_mind/view/widgets/board_widget.dart';
import 'package:mono_games/features/noir_mind/view/widgets/game_over_overlay.dart';
import 'package:mono_games/features/noir_mind/view/widgets/piece_tray_widget.dart';
import 'package:mono_games/features/noir_mind/view/widgets/score_hud_widget.dart';
import 'package:mono_games/features/noir_mind/view_model/noir_mind_view_model.dart';

/// Noir Mindパズルゲームのメイン画面。
class NoirMindScreen extends HookConsumerWidget {
  /// Noir Mind画面を作成する。
  const NoirMindScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isGameOver = ref.watch(
      noirMindViewModelProvider.select((s) => s.isGameOver),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const boardPadding = 20.0;
            final cellSize =
                (constraints.maxWidth - boardPadding * 2) / Board.size;

            return Stack(
              children: [
                // メインゲームレイアウト
                Column(
                  children: [
                    const SizedBox(height: 8),
                    // 上部バー: 戻るボタン
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    // スコアHUD
                    const ScoreHudWidget(),
                    const SizedBox(height: 24),
                    // ボード
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: boardPadding,
                          ),
                          child: BoardWidget(cellSize: cellSize),
                        ),
                      ),
                    ),
                    // ピーストレイ
                    Padding(
                      padding: const EdgeInsets.only(bottom: boardPadding),
                      child: PieceTrayWidget(cellSize: cellSize),
                    ),
                  ],
                ),
                // ゲームオーバーオーバーレイ
                if (isGameOver)
                  const Positioned.fill(
                    child: GameOverOverlay(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
