import 'package:flutter/material.dart';

/// 共通のアニメーション時間・カーブ定数。
///
/// `AnimatedContainer(duration: AppAnimation.normal)` のように使う。
abstract final class AppAnimation {
  // ── Duration ──────────────────────────────────────────────────────
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);

  // ── Curve ─────────────────────────────────────────────────────────
  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;
  static const Curve spring = Curves.elasticOut;
}
