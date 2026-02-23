import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/noir_mind/model/board.dart';
import 'package:mono_games/features/noir_mind/view/modals/theme_selector_sheet.dart';
import 'package:mono_games/features/noir_mind/view/widgets/background_effect_widget.dart';
import 'package:mono_games/features/noir_mind/view/widgets/board_widget.dart';
import 'package:mono_games/features/noir_mind/view/widgets/game_over_overlay.dart';
import 'package:mono_games/features/noir_mind/view/widgets/piece_tray_widget.dart';
import 'package:mono_games/features/noir_mind/view/widgets/score_hud_widget.dart';
import 'package:mono_games/features/noir_mind/view_model/noir_mind_view_model.dart';
import 'package:mono_games/features/noir_mind/view_model/theme_view_model.dart';

/// Noir Mindパズルゲームのメイン画面。
class NoirMindScreen extends HookConsumerWidget {
  /// Noir Mind画面を作成する。
  const NoirMindScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeViewModelProvider);
    final isGameOver = ref.watch(
      noirMindViewModelProvider.select((s) => s.isGameOver),
    );
    final colors = theme.colorsFor(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const boardPadding = 20.0;
            final cellSize =
                (constraints.maxWidth - boardPadding * 2) / Board.size;

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
                    // 上部バー: 戻るボタン + テーマ選択ボタン
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
                          IconButton(
                            icon: Icon(
                              Icons.palette_outlined,
                              color: colors.onSurface.withValues(alpha: 0.6),
                              size: 22,
                            ),
                            onPressed: () => showThemeSelectorSheet(context),
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
              ],
            );
          },
        ),
      ),
    );
  }
}
