import 'dart:async';

import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/game_theme.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/widgets/piece_tray_widget.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/widgets/quiz_choice_panel_widget.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/widgets/quiz_feedback_banner_widget.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/widgets/quiz_input_panel_widget.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/widgets/quiz_meta_chips_widget.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/widgets/quiz_word_header_widget.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:anki_games/common/features/quiz/view_model/quiz_view_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// クイズモード時にボード下部に表示するインラインクイズパネル。
///
/// ViewModel からクイズ UI 状態を読み取り、すべての操作を ViewModel に委譲する。
class InlineQuizPanelWidget extends ConsumerWidget {
  const InlineQuizPanelWidget({
    required this.cellSize,
    required this.theme,
    super.key,
  });

  final double cellSize;
  final GameTheme theme;

  static const _feedbackDuration = Duration(milliseconds: 700);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(blockPuzzleViewModelProvider);
    final quizState = ref.watch(quizViewModelProvider);

    ref
      ..listen<Set<(int, int)>>(
        blockPuzzleViewModelProvider.select((s) => s.lastPlacedCells),
        (prev, next) {
          if (next.isNotEmpty) {
            _onBlockPlaced(ref, ref.read(quizViewModelProvider));
          }
        },
      )
      ..listen<List<QuizQuestion>>(
        quizViewModelProvider.select((s) => s.questions),
        (prev, next) {
          if (next.isNotEmpty &&
              (prev == null ||
                  prev.isEmpty ||
                  prev[0].word.id != next[0].word.id)) {
            final gs = ref.read(blockPuzzleViewModelProvider);
            if (!gs.quizFeedbackShowing) {
              ref
                  .read(blockPuzzleViewModelProvider.notifier)
                  .prepareQuizBlocks(next[0]);
            }
          }
        },
      );

    if (gameState.quizFeedbackShowing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuizFeedbackBannerWidget(
            isCorrect: gameState.quizFeedbackIsCorrect,
            correctAnswer: gameState.quizFeedbackCorrectAnswer,
          ),
          AbsorbPointer(
            child: PieceTrayWidget(cellSize: cellSize, theme: theme),
          ),
        ],
      );
    }

    if (quizState.isLoading || quizState.questions.isEmpty) {
      return SizedBox(
        height: cellSize * 5,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final question = quizState.questions[0];

    // stage 3/4 — ブロック出現前: 入力 UI を表示
    if ((question.format == QuizFormat.letterTap ||
            question.format == QuizFormat.jaToEnTyping) &&
        gameState.pieces.isEmpty) {
      return QuizInputPanelWidget(
        question: question,
        onLetterTapComplete: ({required bool isCorrect}) => ref
            .read(blockPuzzleViewModelProvider.notifier)
            .completeLetterTapInput(isCorrect: isCorrect),
        onTypingComplete: (String text) => ref
            .read(blockPuzzleViewModelProvider.notifier)
            .completeTypingInput(text),
      );
    }

    // stage 3/4 — 入力完了後: ブロックをドラッグして配置
    if (question.format == QuizFormat.letterTap ||
        question.format == QuizFormat.jaToEnTyping) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuizWordHeaderWidget(question: question),
          QuizMetaChipsWidget(question: question),
          const SizedBox(height: 10),
          PieceTrayWidget(cellSize: cellSize, theme: theme),
          const SizedBox(height: 8),
        ],
      );
    }

    // stage 0-2 — 4択: 2×2タップ選択 → ブロック出現 → ドラッグ配置
    return QuizChoicePanelWidget(
      question: question,
      cellSize: cellSize,
      theme: theme,
    );
  }

  void _onBlockPlaced(WidgetRef ref, QuizViewState quizState) {
    final gameState = ref.read(blockPuzzleViewModelProvider);
    if (gameState.quizFeedbackShowing || !gameState.isQuizMode) {
      return;
    }
    if (quizState.questions.isEmpty) {
      return;
    }

    final question = quizState.questions[0];
    final vm = ref.read(blockPuzzleViewModelProvider.notifier);
    final quizVm = ref.read(quizViewModelProvider.notifier);

    if (question.format == QuizFormat.enToJaChoice ||
        question.format == QuizFormat.jaToEnChoice) {
      final choiceIdx = gameState.quizSelectedChoiceIndex;
      if (choiceIdx == null || choiceIdx >= question.choices.length) {
        return;
      }
      quizVm.answer(0, question.choices[choiceIdx].direction);
    } else if (question.format == QuizFormat.letterTap) {
      if (gameState.quizInputIsCorrect == null) {
        return;
      }
      quizVm.answerLetterTap(0, isCorrect: gameState.quizInputIsCorrect!);
    } else if (question.format == QuizFormat.jaToEnTyping) {
      if (gameState.quizTypedText == null) {
        return;
      }
      quizVm.answerWithText(0, gameState.quizTypedText!);
    }

    final answeredState = ref.read(quizViewModelProvider);
    final lastAnswer = answeredState.answers.isNotEmpty
        ? answeredState.answers.last
        : null;
    final isCorrect = lastAnswer?.isCorrect ?? false;
    final correctAnswer = isCorrect
        ? ''
        : switch (question.format) {
            QuizFormat.enToJaChoice => question.word.ja,
            _ => question.word.en,
          };

    vm
      ..setQuizAnswerFeedback(isCorrect: isCorrect)
      ..showQuizFeedback(
        isCorrect: isCorrect,
        correctAnswer: correctAnswer,
      );

    quizVm.startSingleQuestion();

    final feedbackWord = question.word;
    final overdueBonus = lastAnswer?.overdueBonus ?? 0;
    Timer(_feedbackDuration, () {
      vm
        ..clearQuizAnswerFeedback()
        ..hideQuizFeedback()
        ..recordInlineQuizAnswer(
          0,
          isCorrect: isCorrect,
          word: feedbackWord,
          overdueBonus: overdueBonus,
        );

      final nextQuestions = ref.read(quizViewModelProvider).questions;
      if (nextQuestions.isNotEmpty) {
        vm.prepareQuizBlocks(nextQuestions[0]);
      }
    });
  }
}
