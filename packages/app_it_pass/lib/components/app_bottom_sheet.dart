import 'dart:ui';

import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:flutter/material.dart';

/// ボトムシート共通の frosted glass 背景コンテナ。
///
/// 固定高さが必要な場合は [height] を指定する。
/// 指定しない場合は子ウィジェットの高さに合わせて表示する。
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.height,
  });

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: c.surfaceSheet,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: c.border1),
              left: BorderSide(color: c.border1),
              right: BorderSide(color: c.border1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
