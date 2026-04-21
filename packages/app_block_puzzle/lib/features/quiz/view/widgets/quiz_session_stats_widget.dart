import 'package:app_block_puzzle/features/block_puzzle/model/game_theme.dart';
import 'package:core/features/quiz/model/quiz_word.dart';
import 'package:flutter/material.dart';

/// クイズモードのゲームオーバー等で使うセッション統計（正解率・苦手語など）。
class QuizSessionStatsWidget extends StatelessWidget {
  const QuizSessionStatsWidget({
    required this.correctWords,
    required this.incorrectWords,
    required this.tomorrowReviewCount,
    required this.colors,
    super.key,
  });

  final List<QuizWord> correctWords;
  final List<QuizWord> incorrectWords;
  final int tomorrowReviewCount;
  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final total = correctWords.length + incorrectWords.length;
    final correctCount = correctWords.length;

    final seen = <int>{};
    final uniqueIncorrect =
        incorrectWords.where((w) => seen.add(w.id)).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total > 0 ? '$correctCount / $total 正解' : '0 問回答',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: total > 0 ? correctCount / total : 0,
                      minHeight: 6,
                      backgroundColor: colors.onSurface.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (tomorrowReviewCount > 0) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '明日 $tomorrowReviewCount 語を復習できます',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ),
          ),
        ],
        if (uniqueIncorrect.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            '苦手だった単語',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: colors.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          for (final word in uniqueIncorrect)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    word.en,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    word.ja,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
