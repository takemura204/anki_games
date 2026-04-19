import 'dart:math';

import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/board.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/game_theme.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/piece.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/widgets/background_effect_widget.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/widgets/board_widget.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/widgets/game_over_overlay.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/widgets/inline_quiz_panel_widget.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/widgets/piece_tray_widget.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view_model/theme_view_model.dart';
import 'package:anki_games/common/config/styles/app_text_style.dart';
import 'package:anki_games/common/features/admob/admob_banner.dart';
import 'package:anki_games/common/features/purchase/view_model/premium_view_model.dart';
import 'package:anki_games/common/features/quiz/view_model/quiz_view_model.dart';
import 'package:anki_games/common/until/router/modal_sheet_router.dart';
import 'package:anki_games/common/until/router/router_constants.dart';
import 'package:anki_games/common/until/service/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

part 'widgets/game_header_widget.dart';

class BlockPuzzleScreen extends ConsumerWidget {
  const BlockPuzzleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeViewModelProvider);
    final gameState = ref.watch(blockPuzzleViewModelProvider);
    final isPremium = ref.watch(
      premiumViewModelProvider.select((s) => s.valueOrNull?.isPremium ?? false),
    );
    final colors = theme.colorsFor(Theme.of(context).brightness);
    final isTypingMode = gameState.isQuizMode &&
        ref.watch(
          quizViewModelProvider.select(
            (s) =>
                s.questions.isNotEmpty &&
                s.questions[0].format == QuizFormat.jaToEnTyping,
          ),
        );

    ref
      ..listen<List<Piece?>>(
        blockPuzzleViewModelProvider.select((s) => s.pieces),
        (prev, next) {
          if (next.isEmpty && (prev != null && prev.isNotEmpty)) {
            final quizState = ref.read(quizViewModelProvider);
            if (!quizState.isLoading && quizState.questions.isEmpty) {
              ref.read(quizViewModelProvider.notifier).startSingleQuestion();
            }
          }
        },
      )
      ..listen<(bool, int)>(
        quizViewModelProvider.select(
          (s) => (s.isLoading, s.questions.length),
        ),
        ((bool, int)? prev, (bool, int) next) {
          final (prevLoading, _) = prev ?? (false, 0);
          final (nextLoading, nextCount) = next;
          if (prevLoading && !nextLoading && nextCount == 0) {
            TtsService.instance.stop();
            rootNavigatorKey.currentContext?.pop();
          }
        },
      );

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: isTypingMode,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: BackgroundEffectWidget(theme: theme)),
            Column(
              children: [
                const GameHeaderWidget(),
                const Gap(5),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 横幅いっぱいに展開。縦は ボード8 + その他6 = 14 相当を目安にする。
                      const totalCellsForHeight = 14.0;
                      final cellSizeFromWidth =
                          constraints.maxWidth / Board.size;
                      final cellSizeFromHeight =
                          constraints.maxHeight / totalCellsForHeight;
                      final cellSize =
                          min(cellSizeFromWidth, cellSizeFromHeight);

                      if (gameState.isQuizMode) {
                        return _QuizModeLayout(
                          cellSize: cellSize,
                          theme: theme,
                        );
                      }
                      return _ClassicModeLayout(
                        cellSize: cellSize,
                        theme: theme,
                      );
                    },
                  ),
                ),
                if (!isPremium) const AdmobBanner(),
              ],
            ),
            if (gameState.isGameOver)
              Positioned.fill(child: GameOverOverlay(theme: theme)),
          ],
        ),
      ),
    );
  }
}

class _ClassicModeLayout extends StatelessWidget {
  const _ClassicModeLayout({
    required this.cellSize,
    required this.theme,
  });

  final double cellSize;
  final GameTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: BoardWidget(cellSize: cellSize, theme: theme),
          ),
        ),
        PieceTrayWidget(cellSize: cellSize, theme: theme),
      ],
    );
  }
}

class _QuizModeLayout extends StatelessWidget {
  const _QuizModeLayout({
    required this.cellSize,
    required this.theme,
  });

  final double cellSize;
  final GameTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: cellSize * Board.size,
          child: BoardWidget(cellSize: cellSize, theme: theme),
        ),
        Expanded(
          child: InlineQuizPanelWidget(cellSize: cellSize, theme: theme),
        ),
      ],
    );
  }
}
