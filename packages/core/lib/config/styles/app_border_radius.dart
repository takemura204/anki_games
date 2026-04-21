import 'package:flutter/material.dart';

/// 共通の角丸プリセット。
///
/// `decoration: BoxDecoration(borderRadius: AppBorderRadius.lg)` のように使う。
abstract final class AppBorderRadius {
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(24));
  static const full = BorderRadius.all(Radius.circular(999));
}
