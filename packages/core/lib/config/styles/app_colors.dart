import 'package:flutter/material.dart';

/// アプリ横断で使うブランド固定色とセマンティック固定色。
///
/// Material3 の [ColorScheme] で賄えない固定パレットのみ定義する。
/// テーマに依存するカラーは [Theme.of(context).colorScheme] を使うこと。
abstract final class AppColors {
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
  static const learningLevelMastered = Color(0xFF54B9E4);
}
