import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../../view_model/quiz_view_model.dart';

/// 4方向スワイプの選択肢を表すチップウィジェット。
///
/// スワイプ中は [isHighlighted] が true になり視覚的に強調される。
/// テキストが長い場合は [AutoSizeText] が自動縮小する（最小 8pt）。
class DirectionChip extends StatelessWidget {
  /// [DirectionChip] を作成する。
  const DirectionChip({
    required this.text,
    required this.direction,
    required this.isHighlighted,
    super.key,
  });

  /// 表示するテキスト（日本語訳または英単語）。
  final String text;

  /// このチップに対応するスワイプ方向。
  final SwipeDirection direction;

  /// スワイプ中にこの方向が選ばれているかどうか。
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isHighlighted
        ? (isDark ? Colors.white : Colors.black)
        : (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.06));
    final fg = isHighlighted
        ? (isDark ? Colors.black : Colors.white)
        : (isDark
            ? Colors.white.withValues(alpha: 0.8)
            : Colors.black.withValues(alpha: 0.7));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: AutoSizeText(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
          color: fg,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        minFontSize: 8,
      ),
    );
  }
}
