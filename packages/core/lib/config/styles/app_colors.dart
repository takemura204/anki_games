import 'package:flutter/material.dart';

/// アプリ横断で使うブランド固定色とセマンティック固定色。
///
/// Material3 の [ColorScheme] で賄えない固定パレットのみ定義する。
/// テーマに依存するカラーは [Theme.of(context).colorScheme] を使うこと。
abstract final class AppColors {
  // ── Brand seeds ───────────────────────────────────────────────────
  /// IT Pass アプリのブランドカラー（紫）。
  static const itPassSeed = Color(0xFF7C3AED);

  // ── Semantic ──────────────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}
