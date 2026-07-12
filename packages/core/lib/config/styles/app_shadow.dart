import 'package:flutter/material.dart';

/// 共通の影プリセット。
///
/// `BoxDecoration(boxShadow: AppShadow.sm)` のように使う。
abstract final class AppShadow {
  static const sm = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const md = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const lg = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
}
