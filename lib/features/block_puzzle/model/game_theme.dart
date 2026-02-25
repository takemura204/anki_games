import 'package:flutter/material.dart';

// --- Enums ---

/// セルの描画モード。
enum CellRenderMode {
  /// グラスモーフィズム（半透明+縁グロー）。
  glassmorphism,

  /// ワイヤーフレーム（ボーダーのみ発光）。
  wireframe,

  /// グロッシー（ツヤ+大角丸+ハイライトバブル）。
  glossy,

  /// マット（低彩度+微細ノイズ質感）。
  matte,

  /// サンド（砂、高密度ノイズ）。
  sand,

  /// バブル（ビニール、強いハイライト）。
  bubble,

  /// アイス（氷、内部クラック）。
  ice,

  /// スレート（純黒縦グラデーション、ハイライトなし）。
  slate,

  /// スライム（粘液、有機的な表面、サブサーフェス散乱）。
  slime,
}

/// ライン消去時のエフェクトモード。
enum ClearEffectMode {
  /// 白フラッシュ明滅。
  flash,

  /// 画面フラッシュ+グリッチジッター。
  glitch,

  /// 紙吹雪（多色・多形状パーティクル）。
  confetti,

  /// 波紋（同心円拡大）。
  ripple,

  /// 賽の目（細かい正方形に分解）。
  dice,

  /// 崩壊（砂のように流れる）。
  dissolve,

  /// 破裂（弾ける）。
  pop,

  /// 粉砕（氷が砕ける）。
  shatter,
}

/// 背景エフェクトモード。
enum BackgroundMode {
  /// 単色背景。
  solid,

  /// スクロールグリッド+走査線。
  cyberGrid,

  /// グラデーション背景。
  gradient,

  /// 和紙風ノイズテクスチャ。
  paperTexture,
}

/// パーティクルの形状。
enum ParticleShape {
  /// 円。
  circle,

  /// 星。
  star,

  /// 四角。
  square,

  /// ハート。
  heart,

  /// 破片（鋭角な三角形）。
  shard,
}

// --- Data Classes ---

/// ゲームテーマのカラーパレット。
class GameThemeColors {
  /// カラーパレットを作成する。
  const GameThemeColors({
    required this.surface,
    required this.onSurface,
    required this.emptyCellFill,
    required this.gridLine,
    required this.accent,
    required this.highlightTop,
    required this.shadowBottom,
    required this.glowColor,
    required this.particleColor,
    required this.overlayBg,
    this.accentSecondary,
    this.particleColors = const [],
  });

  /// 背景色。
  final Color surface;

  /// ピース・テキスト等の前景色。
  final Color onSurface;

  /// 空セルの塗りつぶし色。
  final Color emptyCellFill;

  /// グリッド線の色。
  final Color gridLine;

  /// アクセントカラー（NEW BEST、コンボバッジ等）。
  final Color accent;

  /// セル上部ハイライトグラデーション色。
  final Color highlightTop;

  /// セル下部シャドウグラデーション色。
  final Color shadowBottom;

  /// 消去プレビューのグロー色。
  final Color glowColor;

  /// デフォルトパーティクル色。
  final Color particleColor;

  /// ゲームオーバーオーバーレイ背景色。
  final Color overlayBg;

  /// セカンダリアクセント色（Neonのマゼンタ等）。
  final Color? accentSecondary;

  /// 多色パーティクル用カラーリスト（空なら[particleColor]を使用）。
  final List<Color> particleColors;
}

/// テーマ別セル描画スタイルのパラメータ。
class GameThemeCellStyle {
  /// セル描画スタイルを作成する。
  const GameThemeCellStyle({
    required this.renderMode,
    this.cellBorderRadius = 3.0,
    this.borderWidth = 0.0,
    this.fillOpacity = 1.0,
    this.blurSigma = 0.0,
    this.chromaticOffset = 0.0,
    this.grainIntensity = 0.0,
  });

  /// 描画モード。
  final CellRenderMode renderMode;

  /// セルの角丸半径。
  final double cellBorderRadius;

  /// ボーダー幅（wireframe用）。
  final double borderWidth;

  /// 塗りつぶしの不透明度。
  final double fillOpacity;

  /// 縁のブラーシグマ（glassmorphism用）。
  final double blurSigma;

  /// 色収差のオフセット（wireframe用、ピクセル）。
  final double chromaticOffset;

  /// ノイズ粒度（matte用、0.0-1.0）。
  final double grainIntensity;
}

/// テーマ別クリアエフェクトのパラメータ。
class GameThemeClearEffect {
  /// クリアエフェクトを作成する。
  const GameThemeClearEffect({
    required this.mode,
    this.flashColor,
    this.confettiShapes = const [],
    this.rippleCount = 3,
    this.rippleMaxRadius = 100.0,
  });

  /// エフェクトモード。
  final ClearEffectMode mode;

  /// フラッシュ色（flash/glitch用）。
  final Color? flashColor;

  /// 紙吹雪の形状リスト（confetti用）。
  final List<ParticleShape> confettiShapes;

  /// 波紋の同心円数（ripple用）。
  final int rippleCount;

  /// 波紋の最大半径（ripple用）。
  final double rippleMaxRadius;
}

/// テーマ別背景エフェクトのパラメータ。
class GameThemeBackground {
  /// 背景エフェクトを作成する。
  const GameThemeBackground({
    required this.mode,
    this.gridLineColor,
    this.gridScrollSpeed = 0.0,
    this.scanlineOpacity = 0.0,
    this.gradientColors = const [],
    this.noiseOpacity = 0.0,
  });

  /// 背景モード。
  final BackgroundMode mode;

  /// グリッド線の色（cyberGrid用）。
  final Color? gridLineColor;

  /// グリッドスクロール速度（px/s、cyberGrid用）。
  final double gridScrollSpeed;

  /// 走査線の不透明度（cyberGrid用）。
  final double scanlineOpacity;

  /// グラデーション色リスト（gradient用）。
  final List<Color> gradientColors;

  /// ノイズの不透明度（paperTexture用）。
  final double noiseOpacity;
}

/// ゲームテーマのアニメーションパラメータ。
class GameThemeAnimations {
  /// アニメーションパラメータを作成する。
  const GameThemeAnimations({
    required this.clearDuration,
    required this.bounceDuration,
    required this.shakeDuration,
    required this.pulseDuration,
    required this.placementCurve,
    required this.shakeIntensity,
    required this.bounceSequence,
    required this.particlesPerCell,
    required this.particleMinSpeed,
    required this.particleMaxSpeed,
    this.cellDelay = 0.05,
  });

  /// ライン消去アニメーションの長さ。
  final Duration clearDuration;

  /// 配置バウンスアニメーションの長さ。
  final Duration bounceDuration;

  /// スクリーンシェイクの長さ。
  final Duration shakeDuration;

  /// 消去プレビューパルスの周期。
  final Duration pulseDuration;

  /// 配置アニメーションのカーブ。
  final Curve placementCurve;

  /// シェイクの最大振幅（ピクセル）。
  final double shakeIntensity;

  /// バウンスシーケンスの値リスト（スケール値）。
  final List<double> bounceSequence;

  /// セルあたりのパーティクル数。
  final int particlesPerCell;

  /// パーティクルの最低速度。
  final double particleMinSpeed;

  /// パーティクルの最高速度。
  final double particleMaxSpeed;

  /// 遅延破壊のセル間遅延（秒）。
  final double cellDelay;
}

/// ゲームテーマのサウンドパス。
class GameThemeSounds {
  /// サウンドパスを作成する。
  const GameThemeSounds({
    this.placePath,
    this.clearPath,
    this.comboPath,
    this.gameOverPath,
    this.clearPitchMin = 0.9,
    this.clearPitchMax = 1.1,
  });

  /// ピース配置時のSEパス。
  final String? placePath;

  /// ライン消去時のSEパス。
  final String? clearPath;

  /// コンボ発生時のSEパス。
  final String? comboPath;

  /// ゲームオーバー時のSEパス。
  final String? gameOverPath;

  /// クリアSEの最低ピッチ（左上セル付近）。
  final double clearPitchMin;

  /// クリアSEの最高ピッチ（右下セル付近）。
  final double clearPitchMax;
}

/// Noir Mindのゲームテーマ。
class GameTheme {
  /// ゲームテーマを作成する。
  const GameTheme({
    required this.id,
    required this.name,
    required this.icon,
    required this.colors,
    required this.animations,
    required this.sounds,
    required this.cellStyle,
    required this.clearEffect,
    required this.background,
    this.colorsDark,
  });

  /// テーマの一意識別子。
  final String id;

  /// テーマの表示名。
  final String name;

  /// テーマのアイコン（絵文字）。
  final String icon;

  /// ライトモード用カラーパレット。
  final GameThemeColors colors;

  /// ダークモード用カラーパレット（nullの場合は[colors]を使用）。
  final GameThemeColors? colorsDark;

  /// ブライトネスに応じたカラーパレットを返す。
  GameThemeColors colorsFor(Brightness brightness) =>
      brightness == Brightness.dark ? (colorsDark ?? colors) : colors;

  /// アニメーションパラメータ。
  final GameThemeAnimations animations;

  /// サウンドパス。
  final GameThemeSounds sounds;

  /// セル描画スタイル。
  final GameThemeCellStyle cellStyle;

  /// クリアエフェクト。
  final GameThemeClearEffect clearEffect;

  /// 背景エフェクト。
  final GameThemeBackground background;
}
