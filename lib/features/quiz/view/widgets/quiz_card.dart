import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mono_games/features/quiz/view/widgets/direction_chip.dart';
import 'package:mono_games/features/quiz/view_model/quiz_view_model.dart';

/// スワイプ式クイズカード本体。
///
/// カード上下左右にチップを配置し、スワイプ中の方向をハイライトする。
/// カードは正方形で画面中央に配置される。
class QuizCard extends StatelessWidget {
  /// [QuizCard] を作成する。
  const QuizCard({
    required this.question,
    required this.activeDirection,
    super.key,
  });

  /// 表示する問題データ。
  final QuizQuestion question;

  /// スワイプ中のアクティブ方向（null なら非選択）。
  final SwipeDirection? activeDirection;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    final upChoice = _choiceFor(SwipeDirection.up);
    final downChoice = _choiceFor(SwipeDirection.down);
    final leftChoice = _choiceFor(SwipeDirection.left);
    final rightChoice = _choiceFor(SwipeDirection.right);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox.square(
            dimension: size,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.4 : 0.12,
                    ),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 上チップ
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: DirectionChip(
                      text: upChoice?.text ?? '',
                      direction: SwipeDirection.up,
                      isHighlighted: activeDirection == SwipeDirection.up,
                    ),
                  ),
                  // カード中央: 単語 + 左右チップ
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        DirectionChip(
                          text: leftChoice?.text ?? '',
                          direction: SwipeDirection.left,
                          isHighlighted: activeDirection == SwipeDirection.left,
                        ),
                        Expanded(
                          child: Text(
                            question.displayText,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        DirectionChip(
                          text: rightChoice?.text ?? '',
                          direction: SwipeDirection.right,
                          isHighlighted:
                              activeDirection == SwipeDirection.right,
                        ),
                      ],
                    ),
                  ),
                  // 下チップ
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: DirectionChip(
                      text: downChoice?.text ?? '',
                      direction: SwipeDirection.down,
                      isHighlighted: activeDirection == SwipeDirection.down,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  QuizChoice? _choiceFor(SwipeDirection dir) {
    final matches = question.choices
        .where((QuizChoice c) => c.direction == dir);
    return matches.isEmpty ? null : matches.first;
  }
}
