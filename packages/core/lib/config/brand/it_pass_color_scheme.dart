import 'package:core/config/brand/it_pass_colors.dart';
import 'package:flutter/material.dart';

export 'package:core/config/brand/it_pass_colors.dart';

/// IT Pass アプリのライト/ダーク対応カラーセット。
///
/// `ThemeData.extensions` に登録し、`BuildContext.appColors` で参照する。
///
/// ## shade 体系（50〜400）
/// ダークモードでは白ベース、ライトモードでは紺黒ベースの不透明度段階。
/// | トークン       | 不透明度 | ダーク代替         | ライト代替       |
/// |---------------|---------|------------------|----------------|
/// | fg            | 100 %   | Colors.white      | dark navy      |
/// | fgShade400    |  ~70 %  | Colors.white70    | black70 相当   |
/// | fgShade300    |  ~54 %  | Colors.white54    | black54 相当   |
/// | fgShade200    |  ~38 %  | Colors.white38    | black38 相当   |
/// | fgShade100    |  ~30 %  | white24〜38        | black30 相当   |
/// | fgShade50     |  ~12 %  | Colors.white12    | black12 相当   |
@immutable
class ItPassColorScheme extends ThemeExtension<ItPassColorScheme> {
  const ItPassColorScheme({
    required this.fg,
    required this.fgShade400,
    required this.fgShade300,
    required this.fgShade200,
    required this.fgShade100,
    required this.fgShade50,
    required this.surface1,
    required this.surface2,
    required this.surfaceSheet,
    required this.border1,
    required this.border2,
    required this.bgGradient,
    required this.bgSolid,
  });

  // ── Foreground shades ─────────────────────────────────────────────
  /// 一次テキスト・アイコン
  final Color fg;

  /// ~70% 前景（副テキスト・アクティブアイコン）
  final Color fgShade400;

  /// ~54% 前景（三次テキスト、Colors.white54 代替）
  final Color fgShade300;

  /// ~38% 前景（無効テキスト、Colors.white38 代替）
  final Color fgShade200;

  /// ~30% 前景（ヒントテキスト、Colors.white24〜38 代替）
  final Color fgShade100;

  /// ~12% 前景（区切り線・背景ヒント、Colors.white12 代替）
  final Color fgShade50;

  // ── Surface ───────────────────────────────────────────────────────
  /// ~4–5% 背景（チップ・ホバー）
  final Color surface1;

  /// ~8% 背景（カード・パネル）
  final Color surface2;

  /// ~95% シートモーダル背景（BackdropFilter 前提）
  final Color surfaceSheet;

  // ── Border ────────────────────────────────────────────────────────
  /// ~12% 境界線（多くのカード・セクションカード）
  final Color border1;

  /// ~20% 境界線（ガラス要素など）
  final Color border2;

  // ── Background ────────────────────────────────────────────────────
  /// 画面背景グラデーション
  final Gradient bgGradient;

  /// 単色背景（参照用）
  final Color bgSolid;

  // ── Presets ───────────────────────────────────────────────────────

  /// ダークモード（紫ベース・現行デザイン）
  static const dark = ItPassColorScheme(
    fg: Color(0xFFFFFFFF),
    fgShade400: Color(0xB3FFFFFF), // 70%
    fgShade300: Color(0x8AFFFFFF), // 54%
    fgShade200: Color(0x61FFFFFF), // 38%
    fgShade100: Color(0x4DFFFFFF), // 30%
    fgShade50: Color(0x1FFFFFFF), // 12%
    surface1: Color(0x0AFFFFFF), // 4%
    surface2: Color(0x14FFFFFF), // 8%
    surfaceSheet: Color(0xF20D0B2B), // itPassBgStart 95%
    border1: Color(0x26FFFFFF), // 15%
    border2: Color(0x33FFFFFF), // 20%
    bgGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        ItPassColors.bgStart,
        ItPassColors.bgMid,
        ItPassColors.bgEnd,
      ],
    ),
    bgSolid: ItPassColors.bgStart,
  );

  /// ライトモード（白/淡ラベンダーベース）
  static const light = ItPassColorScheme(
    fg: Color(0xFF1A1A2E), // ダークネイビー
    fgShade400: Color(0xB31A1A2E), // 70%
    fgShade300: Color(0x8A1A1A2E), // 54%
    fgShade200: Color(0x611A1A2E), // 38%
    fgShade100: Color(0x4D1A1A2E), // 30%
    fgShade50: Color(0x1F1A1A2E), // 12%
    surface1: Color(0x0A1A1A2E), // 4%
    surface2: Color(0x141A1A2E), // 8%
    surfaceSheet: Color(0xF2FFFFFF), // white 95%
    border1: Color(0x261A1A2E), // 15%
    border2: Color(0x331A1A2E), // 20%
    bgGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFF0EEFF), // 淡ラベンダー
        Color(0xFFFAF9FF),
        Color(0xFFFFFFFF),
      ],
    ),
    bgSolid: Color(0xFFFFFFFF),
  );

  // ── ThemeExtension ────────────────────────────────────────────────

  @override
  ItPassColorScheme copyWith({
    Color? fg,
    Color? fgShade400,
    Color? fgShade300,
    Color? fgShade200,
    Color? fgShade100,
    Color? fgShade50,
    Color? surface1,
    Color? surface2,
    Color? surfaceSheet,
    Color? border1,
    Color? border2,
    Gradient? bgGradient,
    Color? bgSolid,
  }) {
    return ItPassColorScheme(
      fg: fg ?? this.fg,
      fgShade400: fgShade400 ?? this.fgShade400,
      fgShade300: fgShade300 ?? this.fgShade300,
      fgShade200: fgShade200 ?? this.fgShade200,
      fgShade100: fgShade100 ?? this.fgShade100,
      fgShade50: fgShade50 ?? this.fgShade50,
      surface1: surface1 ?? this.surface1,
      surface2: surface2 ?? this.surface2,
      surfaceSheet: surfaceSheet ?? this.surfaceSheet,
      border1: border1 ?? this.border1,
      border2: border2 ?? this.border2,
      bgGradient: bgGradient ?? this.bgGradient,
      bgSolid: bgSolid ?? this.bgSolid,
    );
  }

  @override
  ItPassColorScheme lerp(ItPassColorScheme? other, double t) {
    if (other == null) return this;
    return ItPassColorScheme(
      fg: Color.lerp(fg, other.fg, t)!,
      fgShade400: Color.lerp(fgShade400, other.fgShade400, t)!,
      fgShade300: Color.lerp(fgShade300, other.fgShade300, t)!,
      fgShade200: Color.lerp(fgShade200, other.fgShade200, t)!,
      fgShade100: Color.lerp(fgShade100, other.fgShade100, t)!,
      fgShade50: Color.lerp(fgShade50, other.fgShade50, t)!,
      surface1: Color.lerp(surface1, other.surface1, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surfaceSheet: Color.lerp(surfaceSheet, other.surfaceSheet, t)!,
      border1: Color.lerp(border1, other.border1, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      bgGradient:
          Gradient.lerp(bgGradient, other.bgGradient, t) ?? other.bgGradient,
      bgSolid: Color.lerp(bgSolid, other.bgSolid, t)!,
    );
  }
}

extension ItPassThemeX on BuildContext {
  ItPassColorScheme get appColors =>
      Theme.of(this).extension<ItPassColorScheme>() ?? ItPassColorScheme.dark;
}
