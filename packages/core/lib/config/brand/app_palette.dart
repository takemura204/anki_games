import 'package:flutter/material.dart';

/// core 既定ブランドカラー定数（紫系テーマ）。
///
/// 各ウィジェット内では直接参照せず、可能な限り
/// `BuildContext.appColors`（ThemeExtension）を使うこと。
abstract final class AppPalette {
  static const seed = Color(0xFF7C3AED);
  static const accent = Color(0xFF4F46E5);
  static const bgStart = Color(0xFF0D0B2B);
  static const bgMid = Color(0xFF1A0A3C);
  static const bgEnd = Color(0xFF2D1B69);
}
