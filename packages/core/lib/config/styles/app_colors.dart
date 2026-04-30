import 'package:flutter/material.dart';

/// アプリ横断で使うブランド固定色とセマンティック固定色。
///
/// Material3 の [ColorScheme] で賄えない固定パレットのみ定義する。
/// テーマに依存するカラーは [Theme.of(context).colorScheme] を使うこと。
abstract final class AppColors {
  // ── Brand seeds ───────────────────────────────────────────────────
  /// IT Pass アプリのブランドカラー（紫）。seed にも使う。
  static const itPassSeed = Color(0xFF7C3AED);

  /// IT Pass ボタン等グラデーションの末端色（濃紺紫）。
  static const itPassAccent = Color(0xFF4F46E5);

  // ── IT Pass 背景グラデーション ────────────────────────────────────
  /// IT Pass 背景グラデーション最暗部。
  static const itPassBgStart = Color(0xFF0D0B2B);

  /// IT Pass 背景グラデーション中間。
  static const itPassBgMid = Color(0xFF1A0A3C);

  /// IT Pass 背景グラデーション最明部。
  static const itPassBgEnd = Color(0xFF2D1B69);

  // ── Semantic ──────────────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  static const skin1 = MaterialColor(0xFF52C2CD, {
    50: Color(0xFFEFFAFA),
    100: Color(0xFFDAF2F4),
    200: Color(0xFF9FDEE3),
    300: Color(0xFF52C2CD),
    400: Color(0xFF3F959D),
  });

  static const learningLevelUnseen = Color(0xFF9CA3AF);
  static const learningLevelWeak = Color(0xFFFCA5A5);
  static const learningLevelFuzzy = Color(0xFFFCD34D);
  static const learningLevelFamiliar = Color(0xFF6EE7B7);
  static const learningLevelMastered = Color(0xFF7C3AED);
}
