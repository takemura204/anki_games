import 'package:flutter/material.dart';

/// クイズ回答直後に表示する正誤フィードバックバナー。
class QuizFeedbackBannerWidget extends StatelessWidget {
  const QuizFeedbackBannerWidget({
    required this.isCorrect,
    required this.correctAnswer,
    super.key,
  });

  final bool isCorrect;

  /// 不正解時に表示する正解テキスト。正解時は空文字。
  final String correctAnswer;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: accentColor,
            size: 22,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isCorrect
                  ? 'Correct!'
                  : (correctAnswer.isNotEmpty ? '→  $correctAnswer' : '✗'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
