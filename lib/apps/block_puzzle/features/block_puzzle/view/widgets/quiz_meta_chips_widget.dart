import 'package:anki_games/common/features/quiz/view/widgets/quiz_card.dart';
import 'package:anki_games/common/features/quiz/view_model/quiz_view_model.dart';
import 'package:flutter/material.dart';

/// 品詞チップと学習ステータスチップを横並びで表示する。
class QuizMetaChipsWidget extends StatelessWidget {
  const QuizMetaChipsWidget({required this.question, super.key});

  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stageColor = quizStageColor(question.stage);
    final chipBg = isDark
        ? Colors.white10
        : Colors.black.withValues(alpha: 0.06);
    final chipBorder = isDark ? Colors.white24 : Colors.black12;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _MetaChip(
            label: quizPosLabel(question.word.pos),
            color: isDark ? Colors.white60 : Colors.black54,
            bg: chipBg,
            border: chipBorder,
          ),
          const SizedBox(width: 6),
          _MetaChip(
            label: quizStageLabel(question.stage),
            color: stageColor,
            bg: stageColor.withValues(alpha: 0.12),
            border: stageColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
  });

  final String label;
  final Color color;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
