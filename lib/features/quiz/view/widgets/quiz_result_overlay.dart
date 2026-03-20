import 'package:flutter/material.dart';
import 'package:mono_games/features/quiz/model/quiz_result.dart';
import 'package:mono_games/features/quiz/model/quiz_word.dart';
import 'package:mono_games/i18n/translations.g.dart';

/// クイズ3問終了後のサマリーオーバーレイ。
///
/// 正解数バッジ・正誤一覧・次ブロック難易度プレビュー・「ブロックへ」ボタンを表示。
class QuizResultOverlay extends StatelessWidget {
  /// [QuizResultOverlay] を作成する。
  const QuizResultOverlay({
    required this.result,
    required this.isEnToJa,
    required this.onStartBlock,
    super.key,
  });

  /// 3問分のクイズ結果。
  final QuizResult result;

  /// 英→日モードかどうか（正誤一覧の表示方向に使用）。
  final bool isEnToJa;

  /// 「ブロックへ」ボタンが押された時のコールバック。
  final VoidCallback onStartBlock;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final correct = result.correctCount;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 正解数バッジ
              Text(
                t.quiz.result(correct: correct),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              // 正誤一覧
              ...result.answers.map(
                (QuizAnswerResult a) => _AnswerRow(
                  word: a.word,
                  isCorrect: a.isCorrect,
                  correctAnswer: a.correctAnswer,
                  isEnToJa: isEnToJa,
                  textColor: textColor,
                ),
              ),
              const SizedBox(height: 20),
              // 次ブロック難易度プレビュー
              _DifficultyPreview(correctCount: correct, textColor: textColor),
              const SizedBox(height: 24),
              // ブロックへボタン
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onStartBlock,
                  style: TextButton.styleFrom(
                    backgroundColor: textColor,
                    foregroundColor: bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: Text(
                    t.quiz.startBlock,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.word,
    required this.isCorrect,
    required this.correctAnswer,
    required this.isEnToJa,
    required this.textColor,
  });

  final QuizWord word;
  final bool isCorrect;
  final String correctAnswer;
  final bool isEnToJa;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final displayWord = isEnToJa ? word.en : word.ja;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: isCorrect ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$displayWord  →  $correctAnswer',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight:
                    isCorrect ? FontWeight.w400 : FontWeight.w700,
                color: isCorrect
                    ? textColor.withValues(alpha: 0.7)
                    : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyPreview extends StatelessWidget {
  const _DifficultyPreview({
    required this.correctCount,
    required this.textColor,
  });

  final int correctCount;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final (label, dots) = switch (correctCount) {
      3 => ('Easy  ●○○○', 1),
      2 => ('Normal  ●●○○', 2),
      1 => ('Hard  ●●●○', 3),
      _ => ('Very Hard  ●●●●', 4),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Next Block',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
