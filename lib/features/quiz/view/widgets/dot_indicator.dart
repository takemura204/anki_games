import 'package:flutter/material.dart';

/// 3問の進捗を示すドットインジケーター（○●○ スタイル）。
class DotIndicator extends StatelessWidget {
  /// [DotIndicator] を作成する。
  const DotIndicator({
    required this.total,
    required this.current,
    super.key,
  });

  /// 問題総数。
  final int total;

  /// 現在の問題インデックス（0始まり）。
  final int current;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? Colors.white : Colors.black)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
