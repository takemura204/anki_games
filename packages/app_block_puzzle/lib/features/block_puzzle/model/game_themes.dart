import 'package:flutter/animation.dart';

import 'game_theme.dart';

/// Monotone — マットブラック＆オフホワイト（デフォルト）。ミニマルなモノクロデザイン。
const monotoneTheme = GameTheme(
  id: 'monotone',
  name: 'Monotone',
  icon: '\u{2B1B}', // ⬛
  colors: GameThemeColors(
    surface: Color(0xFFFFFFFF), // ホーム画面背景と同一のピュアホワイト
    onSurface: Color(0xFF374142), // マットな近黒ブロック（ベタ塗り）
    emptyCellFill: Color(0xFFDEDEDA), // ウォームライトグレー空セル
    gridLine: Color(0x0F000000), // black 0.06 — 極めて繊細なグリッド
    accent: Color(0xFF6E6E6E), // ミッドグレーアクセント
    highlightTop: Color(0x00FFFFFF), // 完全透明 — グロッシーハイライトを無効化
    shadowBottom: Color(0x08000000), // black 0.03
    glowColor: Color(0xFF2A2A2A),
    particleColor: Color(0xFF8C8C8C),
    overlayBg: Color(0xD9FFFFFF), // white 0.85
  ),
  colorsDark: GameThemeColors(
    surface: Color(0xFF0F0F0F), // 近黒背景
    onSurface: Color(0xFFC8C8C8), // ソフトグレーブロック（ベタ塗り）
    emptyCellFill: Color(0xFF242424), // ダークグレー空セル
    gridLine: Color(0x0FFFFFFF), // white 0.06 — 極めて繊細なグリッド
    accent: Color(0xFF8C8C8C), // ミッドグレーアクセント
    highlightTop: Color(0x00FFFFFF), // 完全透明 — グロッシーハイライトを無効化
    shadowBottom: Color(0x1A000000), // black 0.1
    glowColor: Color(0xFFE8E8E8),
    particleColor: Color(0xFF6E6E6E),
    overlayBg: Color(0xCC0F0F0F), // near-black 0.8
  ),
  cellStyle: GameThemeCellStyle(
    renderMode: CellRenderMode.glossy, // ベタ塗り（highlightTop alpha=0 で無地）
  ),
  clearEffect: GameThemeClearEffect(
    mode: ClearEffectMode.dissolve, // じわっと溶ける消去
  ),
  background: GameThemeBackground(
    mode: BackgroundMode.solid,
  ),
  animations: GameThemeAnimations(
    clearDuration: Duration(milliseconds: 680), // じわっと溶ける
    bounceDuration: Duration(milliseconds: 240),
    shakeDuration: Duration(milliseconds: 200),
    pulseDuration: Duration(milliseconds: 700),
    placementCurve: Curves.easeOutQuart,
    shakeIntensity: 3,
    bounceSequence: [0, 1.05, 0.97, 1.02, 1],
    particlesPerCell: 10,
    particleMinSpeed: 30,
    particleMaxSpeed: 80,
    cellDelay: 0.08,
  ),
  sounds: GameThemeSounds(
    placePath: 'assets/sounds/block_puzzle/put.mp3',
    clearPath: 'assets/sounds/block_puzzle/stone_cut.mp3',
  ),
);

/// Cyber Neon — SF/ゲーマー。
const cyberNeonTheme = GameTheme(
  id: 'cyber_neon',
  name: 'Cyber Neon',
  icon: '\u{1F4A0}', // 💠
  colors: GameThemeColors(
    surface: Color(0xFF0A0A1A),
    onSurface: Color(0xFF00FFCC),
    emptyCellFill: Color(0xFF141428),
    gridLine: Color(0x1A00FFCC), // cyan 0.1
    accent: Color(0xFFFF00FF),
    accentSecondary: Color(0xFFFF00FF),
    highlightTop: Color(0x4000FFCC), // cyan 0.25
    shadowBottom: Color(0x26000033), // deep blue 0.15
    glowColor: Color(0xFF00FFCC),
    particleColor: Color(0xFF00FFCC),
    overlayBg: Color(0xCC0A0A1A), // dark 0.8
    particleColors: [
      Color(0xFF00FFCC),
      Color(0xFFFF00FF),
      Color(0xFF00CCFF),
    ],
  ),
  cellStyle: GameThemeCellStyle(
    renderMode: CellRenderMode.wireframe,
    cellBorderRadius: 2,
    borderWidth: 1.5,
    fillOpacity: 0.05,
    chromaticOffset: 1.5,
  ),
  clearEffect: GameThemeClearEffect(
    mode: ClearEffectMode.glitch,
    flashColor: Color(0xFF00FFCC),
  ),
  background: GameThemeBackground(
    mode: BackgroundMode.cyberGrid,
    gridLineColor: Color(0x1400FFCC), // cyan 0.08
    gridScrollSpeed: 20,
    scanlineOpacity: 0.03,
  ),
  animations: GameThemeAnimations(
    clearDuration: Duration(milliseconds: 560), // 高速デジタル爆発
    bounceDuration: Duration(milliseconds: 240),
    shakeDuration: Duration(milliseconds: 280),
    pulseDuration: Duration(milliseconds: 500),
    placementCurve: Curves.elasticOut,
    shakeIntensity: 6,
    bounceSequence: [0, 1.12, 0.90, 1.05, 0.98, 1], // デジタル弾性
    particlesPerCell: 14, // ピクセル破片
    particleMinSpeed: 60,
    particleMaxSpeed: 150,
    cellDelay: 0.08,
  ),
  sounds: GameThemeSounds(
    placePath: 'assets/sounds/block_puzzle/put.mp3',
    clearPath: 'assets/sounds/block_puzzle/neon_cut.mp3',
    clearPitchMax: 1.2,
  ),
);

/// Slime — ASMR/スライム。粘液感あふれるプチプチ消去。
const slimeTheme = GameTheme(
  id: 'slime',
  name: 'Slime',
  icon: '\u{1F7E2}', // 🟢
  colors: GameThemeColors(
    surface: Color(0xFFE8F5E9), // 薄いグリーン
    onSurface: Color(0xFF43A047), // ミディアムグリーン（ピース）
    emptyCellFill: Color(0xFFC8E6C9),
    gridLine: Color(0x2643A047), // green 0.15
    accent: Color(0xFF76FF03), // ライムグリーン
    highlightTop: Color(0x80FFFFFF), // white 0.5
    shadowBottom: Color(0x331B5E20), // deep green 0.2
    glowColor: Color(0xFFA5D6A7), // 薄緑グロー
    particleColor: Color(0xFF66BB6A),
    overlayBg: Color(0xD9C8E6C9), // soft green 0.85
    particleColors: [
      Color(0xFF66BB6A),
      Color(0xFF76FF03),
      Color(0xFF00E676),
    ],
  ),
  cellStyle: GameThemeCellStyle(
    renderMode: CellRenderMode.slime, // 粘液感（専用シェーダー）
    cellBorderRadius: 12,
    fillOpacity: 0.75,
  ),
  clearEffect: GameThemeClearEffect(
    mode: ClearEffectMode.pop, // プチっと破裂
    confettiShapes: [ParticleShape.circle],
  ),
  background: GameThemeBackground(
    mode: BackgroundMode.gradient,
    gradientColors: [
      Color(0xFFE8F5E9),
      Color(0xFFF1F8E9),
    ],
  ),
  animations: GameThemeAnimations(
    clearDuration: Duration(milliseconds: 520), // 弾けるポップ感
    bounceDuration: Duration(milliseconds: 500), // 粘液の弾性
    shakeDuration: Duration(milliseconds: 220),
    pulseDuration: Duration(milliseconds: 550),
    placementCurve: Curves.elasticOut,
    shakeIntensity: 3,
    bounceSequence: [0, 1.28, 0.83, 1.14, 0.95, 1.03, 1], // 粘液の伸び縮み
    particlesPerCell: 16, // 緑の飛沫
    particleMinSpeed: 60,
    particleMaxSpeed: 150,
    cellDelay: 0.06, // 次々とポップ
  ),
  sounds: GameThemeSounds(
    placePath: 'assets/sounds/block_puzzle/put.mp3',
    clearPath: 'assets/sounds/block_puzzle/slime_cut.mp3',
    clearPitchMin: 0.85,
    clearPitchMax: 1.2,
  ),
);

/// Soap Cut — ASMR/石鹸カット。砂粒テクスチャで石鹸バーの質感を再現。
const soapCutTheme = GameTheme(
  id: 'soap_cut',
  name: 'Soap Cut',
  icon: '\u{1F9FC}', // 🧼
  colors: GameThemeColors(
    surface: Color(0xFFE0F7FA), // 薄いシアン背景
    onSurface: Color(0xFF4DD0E1), // シアン（シェーダーのuBase）
    emptyCellFill: Color(0xFFB2EBF2), // 薄いシアン空セル
    gridLine: Color(0x264DD0E1),
    accent: Color(0xFFFFCC80), // ウォームアクセント
    highlightTop: Color(0x40FFFFFF),
    shadowBottom: Color(0x260097A7),
    glowColor: Color(0xFF80DEEA), // ライトシアン（シェーダーのuGlow）
    particleColor: Color(0xFF4DD0E1),
    overlayBg: Color(0xB3B2EBF2),
    particleColors: [
      Color(0xFF4DD0E1),
      Color(0xFF80DEEA),
      Color(0xFFB2EBF2),
    ],
  ),
  cellStyle: GameThemeCellStyle(
    renderMode: CellRenderMode.matte, // 石鹸バーの砂粒質感
    cellBorderRadius: 4, // 石鹸バーの面取り
  ),
  clearEffect: GameThemeClearEffect(
    mode: ClearEffectMode.dissolve, // 石鹸が溶ける
  ),
  background: GameThemeBackground(
    mode: BackgroundMode.gradient,
    gradientColors: [
      Color(0xFFE0F7FA),
      Color(0xFFB2EBF2),
    ],
  ),
  animations: GameThemeAnimations(
    clearDuration: Duration(milliseconds: 680), // じわじわ溶ける
    bounceDuration: Duration(milliseconds: 220),
    shakeDuration: Duration(milliseconds: 160),
    pulseDuration: Duration(milliseconds: 700),
    placementCurve: Curves.easeOutQuart,
    shakeIntensity: 2,
    bounceSequence: [0, 1.05, 0.97, 1.02, 1],
    particlesPerCell: 12,
    particleMinSpeed: 20,
    particleMaxSpeed: 70,
    cellDelay: 0.10,
  ),
  sounds: GameThemeSounds(
    placePath: 'assets/sounds/block_puzzle/put.mp3',
    clearPath: 'assets/sounds/block_puzzle/soap_cut.mp3',
    clearPitchMin: 0.85,
  ),
);

/// Bubble Wrap — 爽快・ポップ系。
const bubbleWrapTheme = GameTheme(
  id: 'bubble_wrap',
  name: 'Bubble Wrap',
  icon: '\u{1F9E7}', // 🧧 (代用: 赤い封筒 -> プチプチっぽいアイコンが少ないため)
  // icon: '🔵',
  colors: GameThemeColors(
    surface: Color(0xFFE3F2FD), // 薄い青
    onSurface: Color(0xFF2196F3), // 青
    emptyCellFill: Color(0xFFBBDEFB),
    gridLine: Color(0x262196F3),
    accent: Color(0xFFFF4081), // ピンク
    highlightTop: Color(0x80FFFFFF), // 強いハイライト
    shadowBottom: Color(0x260D47A1),
    glowColor: Color(0xFF64B5F6),
    particleColor: Color(0xFF2196F3),
    overlayBg: Color(0x99E3F2FD),
    particleColors: [
      Color(0xFF2196F3),
      Color(0xFF00BCD4),
      Color(0xFFFF4081),
    ],
  ),
  cellStyle: GameThemeCellStyle(
    renderMode: CellRenderMode.bubble, // ビニール質感
    cellBorderRadius: 50, // 真ん丸
    fillOpacity: 0.6, // 半透明
  ),
  clearEffect: GameThemeClearEffect(
    mode: ClearEffectMode.pop, // 破裂
    confettiShapes: [ParticleShape.circle],
  ),
  background: GameThemeBackground(
    mode: BackgroundMode.gradient,
    gradientColors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
  ),
  animations: GameThemeAnimations(
    clearDuration: Duration(milliseconds: 480), // 瞬間プチっ！
    bounceDuration: Duration(milliseconds: 450), // ビニールの弾性
    shakeDuration: Duration(milliseconds: 200),
    pulseDuration: Duration(milliseconds: 500),
    placementCurve: Curves.elasticOut,
    shakeIntensity: 4,
    bounceSequence: [0, 1.35, 0.82, 1.18, 0.95, 1.04, 1], // 大げさなバネ
    particlesPerCell: 18, // 飛び散る水滴
    particleMinSpeed: 70,
    particleMaxSpeed: 170,
    cellDelay: 0.045, // 高速連続ポップ
  ),
  sounds: GameThemeSounds(
    placePath: 'assets/sounds/block_puzzle/put.mp3',
    clearPath: 'assets/sounds/block_puzzle/bubble_cut.mp3',
    clearPitchMin: 0.95,
    clearPitchMax: 1.3,
  ),
);

/// Ice & Glass — 美麗・クール系。
const iceGlassTheme = GameTheme(
  id: 'ice_glass',
  name: 'Ice & Glass',
  icon: '\u{1F9CA}', // 🧊
  colors: GameThemeColors(
    surface: Color(0xFFECEFF1), // 薄いグレー
    onSurface: Color(0xFF607D8B), // ブルーグレー
    emptyCellFill: Color(0xFFCFD8DC),
    gridLine: Color(0x1A607D8B),
    accent: Color(0xFF00BCD4), // シアン
    highlightTop: Color(0xCCFFFFFF), // 鋭いハイライト
    shadowBottom: Color(0x1A263238),
    glowColor: Color(0xFFB2EBF2),
    particleColor: Color(0xFFB0BEC5), // 破片色
    overlayBg: Color(0xB3ECEFF1),
  ),
  cellStyle: GameThemeCellStyle(
    renderMode: CellRenderMode.ice, // 氷の質感
    cellBorderRadius: 2,
    fillOpacity: 0.5,
  ),
  clearEffect: GameThemeClearEffect(
    mode: ClearEffectMode.shatter, // 粉砕
    confettiShapes: [ParticleShape.shard],
  ),
  background: GameThemeBackground(
    mode: BackgroundMode.gradient,
    gradientColors: [
      Color(0xFFECEFF1),
      Color(0xFFE0F7FA),
    ], // 冷たいグラデーション
  ),
  animations: GameThemeAnimations(
    clearDuration: Duration(milliseconds: 700),
    bounceDuration: Duration(milliseconds: 180), // 硬質な衝撃
    shakeDuration: Duration(milliseconds: 350), // 粉砕の余震
    pulseDuration: Duration(milliseconds: 1000),
    placementCurve: Curves.decelerate,
    shakeIntensity: 5, // 強いシャッター衝撃
    bounceSequence: [0, 1.02, 0.99, 1], // 氷は弾まない
    particlesPerCell: 14, // 鋭い氷の破片
    particleMinSpeed: 80,
    particleMaxSpeed: 180, // 高速で飛び散る
    cellDelay: 0.06, // 鋭いカスケード
  ),
  sounds: GameThemeSounds(
    placePath: 'assets/sounds/block_puzzle/put.mp3',
    clearPath: 'assets/sounds/block_puzzle/ice_cut.mp3',
    clearPitchMin: 0.75,
    clearPitchMax: 1.05,
  ),
);

/// 全テーマのリスト。
const List<GameTheme> allGameThemes = [
  monotoneTheme,
  cyberNeonTheme,
  slimeTheme,
  soapCutTheme,
  bubbleWrapTheme,
  iceGlassTheme,
];

/// テーマIDからテーマを取得する。見つからない場合はデフォルトを返す。
GameTheme getThemeById(String id) {
  return allGameThemes.firstWhere(
    (t) => t.id == id,
    orElse: () => monotoneTheme,
  );
}
