import 'package:core/features/quiz/view/widgets/quiz_card.dart';
import 'package:core/features/quiz/view_model/quiz_view_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'quiz_meta_chips_widget.dart';
import 'quiz_word_header_widget.dart';

/// letterTap / タイピング入力パネル。
///
/// 問題文・メタチップ・入力UIを縦に並べる。
/// 入力完了後は VM 側がトレイにブロックを出現させる。
class QuizInputPanelWidget extends ConsumerWidget {
  const QuizInputPanelWidget({
    required this.question,
    required this.onLetterTapComplete,
    required this.onTypingComplete,
    super.key,
  });

  final QuizQuestion question;
  final void Function({required bool isCorrect}) onLetterTapComplete;
  final void Function(String text) onTypingComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QuizWordHeaderWidget(question: question),
        QuizMetaChipsWidget(question: question),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: question.format == QuizFormat.letterTap
              ? LetterTapInputBody(
                  key: ValueKey(question.word.id),
                  question: question,
                  onComplete: onLetterTapComplete,
                )
              : TypingInputBody(
                  key: ValueKey(question.word.id),
                  question: question,
                  onComplete: onTypingComplete,
                ),
        ),
      ],
    );
  }
}
