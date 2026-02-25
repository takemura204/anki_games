import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';

/// セル1つを描画する。
///
/// [canvas] に [rect] の領域に [style] と [colors] に基づいてセルを描く。
/// [opacity] はフェードアウト等に使う全体不透明度。
/// [shader] が非nullの場合はGLSLシェーダーで描画する（Canvasフォールバックあり）。
/// [time] はシェーダーアニメーション用の時刻（秒）。
void drawCell(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors, {
  double opacity = 1.0,
  FragmentShader? shader,
  double time = 0.0,
}) {
  if (shader != null) {
    _drawWithShader(canvas, rect, style, colors, opacity, time, shader);
    return;
  }
  switch (style.renderMode) {
    case CellRenderMode.glassmorphism:
      _drawGlassmorphism(canvas, rect, style, colors, opacity);
    case CellRenderMode.wireframe:
      _drawWireframe(canvas, rect, style, colors, opacity);
    case CellRenderMode.glossy:
      _drawGlossy(canvas, rect, style, colors, opacity);
    case CellRenderMode.matte:
      _drawMatte(canvas, rect, style, colors, opacity);
    case CellRenderMode.sand:
      _drawSand(canvas, rect, style, colors, opacity);
    case CellRenderMode.bubble:
      _drawBubble(canvas, rect, style, colors, opacity);
    case CellRenderMode.ice:
      _drawIce(canvas, rect, style, colors, opacity);
    case CellRenderMode.slate:
      _drawSlate(canvas, rect, style, colors, opacity);
    case CellRenderMode.slime:
      _drawSlime(canvas, rect, style, colors, opacity);
  }
}

/// シェーダーを使ってセルを描画する。
///
/// Uniform レイアウト（全シェーダー共通）:
///   [0,1]  uSize   — セルの幅・高さ（px）
///   [2,3]  uOrigin — セルの左上位置（canvas座標）
///   [4]    uTime   — アニメーション時刻（秒）
///   [5-8]  uBase   — onSurface カラー (r,g,b,a)
///   [9-12] uGlow   — glowColor (r,g,b,a)
///   [13]   uOpacity — 全体不透明度
void _drawWithShader(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors,
  double opacity,
  double time,
  FragmentShader shader,
) {
  shader
    ..setFloat(0, rect.width)
    ..setFloat(1, rect.height)
    ..setFloat(2, rect.left)
    ..setFloat(3, rect.top)
    ..setFloat(4, time)
    ..setFloat(5, colors.onSurface.r)
    ..setFloat(6, colors.onSurface.g)
    ..setFloat(7, colors.onSurface.b)
    ..setFloat(8, colors.onSurface.a)
    ..setFloat(9, colors.glowColor.r)
    ..setFloat(10, colors.glowColor.g)
    ..setFloat(11, colors.glowColor.b)
    ..setFloat(12, colors.glowColor.a)
    ..setFloat(13, opacity);

  final rrect = RRect.fromRectAndRadius(
    rect,
    Radius.circular(style.cellBorderRadius),
  );
  canvas.drawRRect(rrect, Paint()..shader = shader);
}

/// グラスモーフィズム: 半透明塗り + 縁グロー + 薄い白トップグラデ。
void _drawGlassmorphism(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors,
  double opacity,
) {
  final rrect = RRect.fromRectAndRadius(
    rect,
    Radius.circular(style.cellBorderRadius),
  );

  // 半透明ベース
  final basePaint = Paint()
    ..color = colors.onSurface.withValues(
      alpha: style.fillOpacity * opacity,
    );
  canvas.drawRRect(rrect, basePaint);

  // 縁グロー（MaskFilter.blur）
  if (style.blurSigma > 0) {
    final glowPaint = Paint()
      ..color = colors.glowColor.withValues(alpha: 0.25 * opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, style.blurSigma);
    canvas.drawRRect(rrect, glowPaint);
  }

  // 上部ハイライト（薄い白グラデ）
  final highlightPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colors.highlightTop.withValues(
          alpha: colors.highlightTop.a * opacity,
        ),
        colors.highlightTop.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.5],
    ).createShader(rect);
  canvas.drawRRect(rrect, highlightPaint);
}

/// ワイヤーフレーム: ボーダーのみ + 色収差 + 極薄塗り。
void _drawWireframe(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors,
  double opacity,
) {
  final rrect = RRect.fromRectAndRadius(
    rect,
    Radius.circular(style.cellBorderRadius),
  );

  // 極薄塗りつぶし
  if (style.fillOpacity > 0) {
    final fillPaint = Paint()
      ..color = colors.onSurface.withValues(
        alpha: style.fillOpacity * opacity,
      );
    canvas.drawRRect(rrect, fillPaint);
  }

  // 色収差（マゼンタ/セカンダリをオフセット描画）
  if (style.chromaticOffset > 0 && colors.accentSecondary != null) {
    final offsetRRect = rrect.shift(
      Offset(style.chromaticOffset, style.chromaticOffset),
    );
    final chromaticPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.borderWidth
      ..color = colors.accentSecondary!.withValues(alpha: 0.4 * opacity);
    canvas.drawRRect(offsetRRect, chromaticPaint);
  }

  // メインボーダー（シアン/onSurface）
  final borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = style.borderWidth
    ..color = colors.onSurface.withValues(alpha: 0.9 * opacity);
  canvas.drawRRect(rrect, borderPaint);
}

/// グロッシー: 大角丸 + RadialGradientハイライトバブル。
void _drawGlossy(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors,
  double opacity,
) {
  final rrect = RRect.fromRectAndRadius(
    rect,
    Radius.circular(style.cellBorderRadius),
  );

  // ベース塗り
  final basePaint = Paint()
    ..color = colors.onSurface.withValues(alpha: opacity);
  canvas.drawRRect(rrect, basePaint);

  // RadialGradient ハイライトバブル（左上）
  // highlightTop の alpha がシーンの光沢強度を決める（glossy: 0.4、satin: ~0.1）
  final highlightAlpha = colors.highlightTop.a * opacity;
  final highlightPaint = Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.6, -0.6),
      radius: 1.2,
      colors: [
        Colors.white.withValues(alpha: highlightAlpha),
        Colors.white.withValues(alpha: 0),
      ],
    ).createShader(rect);
  canvas.drawRRect(rrect, highlightPaint);
}

/// マット: 低彩度ベタ塗り + 微細ノイズドットで石質感。
void _drawMatte(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors,
  double opacity,
) {
  final rrect = RRect.fromRectAndRadius(
    rect,
    Radius.circular(style.cellBorderRadius),
  );

  // ベベル（面取り）処理: 上面と側面を描き分ける
  const bevel = 4.0;
  final topRect = Rect.fromLTRB(
    rect.left + bevel,
    rect.top + bevel,
    rect.right - bevel,
    rect.bottom - bevel,
  );

  // 側面（暗い色）
  final sidePath = Path()
    ..addRRect(rrect)
    ..addRect(topRect)
    ..fillType = PathFillType.evenOdd;
  final sidePaint = Paint()
    ..color = colors.onSurface.withValues(alpha: opacity);
  canvas.drawPath(sidePath, sidePaint);

  // 上面（明るい色）
  final topPaint = Paint()
    ..color = colors.glowColor.withValues(alpha: opacity);
  canvas.drawRect(topRect, topPaint);

  // ノイズドット（grainIntensity > 0の場合）
  if (style.grainIntensity > 0) {
    canvas
      ..save()
      ..clipRect(topRect);
    _drawGrainNoise(canvas, topRect, style.grainIntensity, opacity);
    canvas.restore();
  }
}

/// ノイズドットを矩形領域に描画する。
void _drawGrainNoise(
  Canvas canvas,
  Rect rect,
  double intensity,
  double opacity, {
  int densityScale = 1,
}) {
  // セルサイズに応じたドット数（安定したシード）
  final seed = (rect.left * 7 + rect.top * 13).toInt();
  final rng = Random(seed);
  final dotCount =
      (rect.width * rect.height * 0.04 * intensity * densityScale).toInt();

  final points = <Offset>[];
  for (var i = 0; i < dotCount; i++) {
    points.add(
      Offset(
        rect.left + rng.nextDouble() * rect.width,
        rect.top + rng.nextDouble() * rect.height,
      ),
    );
  }

  if (points.isNotEmpty) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15 * intensity * opacity)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawPoints(PointMode.points, points, paint);
  }
}

/// サンド: ザラついた表面 + 濃いノイズ。
void _drawSand(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors,
  double opacity,
) {
  final rrect = RRect.fromRectAndRadius(
    rect,
    Radius.circular(style.cellBorderRadius),
  );

  // 放射状グラデーション（こんもり感）
  final moundPaint = Paint()
    ..shader = RadialGradient(
      radius: 0.7,
      colors: [
        colors.onSurface.withValues(alpha: opacity),
        colors.shadowBottom.withValues(alpha: opacity),
      ],
    ).createShader(rect);
  // 高密度ノイズ（砂粒）- 先に描画してから save/clip/noise/restore
  canvas
    ..drawRRect(rrect, moundPaint)
    ..save()
    ..clipRRect(rrect);
  _drawGrainNoise(canvas, rect, 1, opacity, densityScale: 3);
  canvas.restore();
}

/// バブル: ビニール質感 + 強烈なハイライト + 透過。
void _drawBubble(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors,
  double opacity,
) {
  // 円形に近いほどプチプチ感が出るので、角丸を強制的に大きくする
  final rradius = rect.width / 2.5;
  final rrect = RRect.fromRectAndRadius(
    rect,
    Radius.circular(rradius),
  );

  // ドロップシャドウ（浮遊感）
  final shadowPath = Path()
    ..addOval(
      Rect.fromCenter(
        center: rect.center.translate(0, 4),
        width: rect.width * 0.8,
        height: rect.height * 0.8,
      ),
    );
  canvas.drawShadow(
      shadowPath, Colors.black.withValues(alpha: 0.3 * opacity), 4, true);

  // ベース（半透明、光沢感のある色）
  final basePaint = Paint()
    ..color = colors.onSurface.withValues(alpha: 0.6 * opacity);
  canvas.drawRRect(rrect, basePaint);

  // 内部グラデーション（立体感）
  final innerGlowPaint = Paint()
    ..shader = RadialGradient(
      radius: 0.8,
      colors: [
        Colors.white.withValues(alpha: 0.2 * opacity),
        Colors.transparent,
      ],
    ).createShader(rect);
  canvas.drawRRect(rrect, innerGlowPaint);

  // 強いハイライト（左上）- より鋭く
  final highlightPath = Path()
    ..addOval(
      Rect.fromLTWH(
        rect.left + rect.width * 0.25,
        rect.top + rect.height * 0.25,
        rect.width * 0.2,
        rect.height * 0.12,
      ),
    );
  final highlightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.9 * opacity)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
  canvas.drawPath(highlightPath, highlightPaint);

  // リムライト（右下）- 輪郭強調
  final rimPath = Path()
    ..addArc(
      Rect.fromLTWH(
        rect.left + rect.width * 0.1,
        rect.top + rect.height * 0.1,
        rect.width * 0.8,
        rect.height * 0.8,
      ),
      0.5,
      2,
    );
  final rimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..color = Colors.white.withValues(alpha: 0.5 * opacity);
  canvas.drawPath(rimPath, rimPaint);
}

/// スレート: ベベル（面取り）+ 上面縦グラデ + 薄い上端ハイライト。
///
/// エッジ（純黒）→ 上面（glowColor→onSurface グラデ）で立体的なブロック感を出す。
/// ハイライト強度は [GameThemeColors.highlightTop] の alpha で制御する。
void _drawSlate(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors,
  double opacity,
) {
  const bevel = 1.5;
  final rrect = RRect.fromRectAndRadius(
    rect,
    Radius.circular(style.cellBorderRadius),
  );

  // ① エッジ（側面）: 純黒で全体を塗る
  final edgePaint = Paint()
    ..color = colors.onSurface.withValues(alpha: opacity);
  canvas.drawRRect(rrect, edgePaint);

  // ② 上面（ベベル内側）: glowColor（明）→ onSurface（暗）の縦グラデーション
  final topRect = Rect.fromLTRB(
    rect.left + bevel,
    rect.top + bevel,
    rect.right - bevel,
    rect.bottom - bevel,
  );
  final innerRadius =
      (style.cellBorderRadius - bevel).clamp(0.0, double.infinity);
  final topRRect = RRect.fromRectAndRadius(
    topRect,
    Radius.circular(innerRadius),
  );
  final topPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colors.glowColor.withValues(alpha: opacity),
        colors.onSurface.withValues(alpha: opacity),
      ],
    ).createShader(topRect);
  canvas.drawRRect(topRRect, topPaint);

  // ③ 上端ハイライト: highlightTop.a に基づく薄い白グラデ
  final highlightAlpha = colors.highlightTop.a * opacity;
  final highlightPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: highlightAlpha),
        Colors.white.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.4],
    ).createShader(rect);
  canvas.drawRRect(rrect, highlightPaint);
}

/// スライム: 半透明グリーン + 中央サブサーフェスグロー + 白いシーン（Canvas フォールバック）。
void _drawSlime(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors,
  double opacity,
) {
  final rrect = RRect.fromRectAndRadius(
    rect,
    Radius.circular(style.cellBorderRadius),
  );

  // ベース（半透明グリーン）
  final basePaint = Paint()
    ..color = colors.onSurface.withValues(alpha: 0.82 * opacity);
  canvas.drawRRect(rrect, basePaint);

  // サブサーフェスグロー（中央から glowColor が滲む）
  final sssPaint = Paint()
    ..shader = RadialGradient(
      radius: 0.55,
      colors: [
        colors.glowColor.withValues(alpha: 0.28 * opacity),
        Colors.transparent,
      ],
    ).createShader(rect);
  canvas.drawRRect(rrect, sssPaint);

  // 表面シーン（左上の白いハイライト）
  final sheenPaint = Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.4, -0.5),
      radius: 0.9,
      colors: [
        Colors.white.withValues(alpha: 0.55 * opacity),
        Colors.white.withValues(alpha: 0),
      ],
    ).createShader(rect);
  canvas.drawRRect(rrect, sheenPaint);
}

/// アイス: 透明感 + 鋭利なライン + 内部クラック。
void _drawIce(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors,
  double opacity,
) {
  // 氷は角ばっている
  final rrect = RRect.fromRectAndRadius(
    rect,
    const Radius.circular(2),
  );

  // ベース（透明度高め、冷たい感じ）
  final basePaint = Paint()
    ..color = colors.onSurface.withValues(alpha: 0.3 * opacity);
  canvas.drawRRect(rrect, basePaint);

  // インナーボーダー（厚み表現）
  final innerBorderRect = rect.deflate(2);
  final innerRRect = RRect.fromRectAndRadius(
    innerBorderRect,
    const Radius.circular(1),
  );
  final innerBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = Colors.white.withValues(alpha: 0.4 * opacity);
  canvas.drawRRect(innerRRect, innerBorderPaint);

  // 表面の反射（線形で鋭く）
  final sheenPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.7 * opacity),
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.2 * opacity),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    ).createShader(rect);
  canvas.drawRRect(rrect, sheenPaint);

  // 内部クラック（ひび割れ）
  final seed = (rect.left * 11 + rect.top * 17).toInt();
  final rng = Random(seed);
  if (rng.nextDouble() < 0.3) {
    final p1 = Offset(
      rect.left + rng.nextDouble() * rect.width,
      rect.top + rng.nextDouble() * rect.height,
    );
    final p2 = Offset(
      rect.left + rng.nextDouble() * rect.width,
      rect.top + rng.nextDouble() * rect.height,
    );
    final crackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6 * opacity)
      ..strokeWidth = 1;
    canvas.drawLine(p1, p2, crackPaint);
  }

  // エッジ強調（外枠）
  final borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = Colors.white.withValues(alpha: 0.5 * opacity);
  canvas.drawRRect(rrect, borderPaint);
}
