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

/// 石鹸カット: 3色レイヤー + 対角ハイライト + ワックスエッジ（Canvas フォールバック）。
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

  // 3色レイヤー: 縦グラデーションで断面の層を表現
  final topColor = Color.lerp(colors.glowColor, const Color(0xFFFFFFF8), 0.50)!;
  final bottomColor =
      Color.lerp(colors.onSurface, const Color(0xFF2E8090), 0.35)!;
  final layerPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        topColor.withValues(alpha: opacity),
        colors.onSurface.withValues(alpha: opacity),
        bottomColor.withValues(alpha: opacity),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rect);
  canvas.drawRRect(rrect, layerPaint);

  // 強いベベル（立体感）
  const bevel = 3.5;
  final bevelRect = Rect.fromLTRB(
    rect.left + bevel,
    rect.top + bevel,
    rect.right - bevel,
    rect.bottom - bevel,
  );
  final innerRRect = RRect.fromRectAndRadius(
    bevelRect,
    Radius.circular((style.cellBorderRadius - bevel).clamp(0.0, 100.0)),
  );
  final bevelPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.18 * opacity),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.14 * opacity),
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(rect);
  canvas.drawRRect(innerRRect, bevelPaint);

  // 対角ハイライト（右上から左下方向への白い光の帯）
  final diagPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.42 * opacity),
        Colors.white.withValues(alpha: 0.18 * opacity),
        Colors.transparent,
      ],
      stops: const [0.0, 0.22, 0.55],
    ).createShader(rect);
  canvas.drawRRect(rrect, diagPaint);

  // ワックスエッジ（半透明な縁の光沢）
  final waxPaint = Paint()
    ..shader = RadialGradient(
      radius: 1,
      colors: [
        Colors.transparent,
        colors.glowColor.withValues(alpha: 0.28 * opacity),
      ],
      stops: const [0.65, 1.0],
    ).createShader(rect);
  canvas.drawRRect(rrect, waxPaint);

  // グレイン（粉っぽいテクスチャ）
  if (style.grainIntensity > 0) {
    canvas
      ..save()
      ..clipRRect(rrect);
    _drawGrainNoise(canvas, rect, style.grainIntensity, opacity);
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

/// バブル: 3D球面 + 鋭いスペキュラー + 虹色リム + ボトムシャドウ（Canvas フォールバック）。
void _drawBubble(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors,
  double opacity,
) {
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
    shadowPath,
    Colors.black.withValues(alpha: 0.3 * opacity),
    4,
    true,
  );

  // ベース（半透明ビニール）
  final basePaint = Paint()
    ..color = colors.onSurface.withValues(alpha: 0.60 * opacity);
  canvas.drawRRect(rrect, basePaint);

  // 上部ライト → 下部シャドウ（3D球体の深度）
  final depthPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0.14 * opacity),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.12 * opacity),
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(rect);
  canvas.drawRRect(rrect, depthPaint);

  // 虹色リム（Fresnel 近似: エッジだけ glow色）
  final iridPaint = Paint()
    ..shader = RadialGradient(
      radius: 1,
      colors: [
        Colors.transparent,
        colors.glowColor.withValues(alpha: 0.35 * opacity),
      ],
      stops: const [0.55, 1.0],
    ).createShader(rect);
  canvas.drawRRect(rrect, iridPaint);

  // 鋭いプライマリスペキュラー（上部左寄り）
  final specRect = Rect.fromLTWH(
    rect.left + rect.width * 0.24,
    rect.top + rect.height * 0.22,
    rect.width * 0.22,
    rect.height * 0.10,
  );
  canvas.drawOval(
    specRect,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.92 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
  );

  // リムライト輪郭（上半分）
  final rimPath = Path()
    ..addArc(
      Rect.fromLTWH(
        rect.left + rect.width * 0.08,
        rect.top + rect.height * 0.08,
        rect.width * 0.84,
        rect.height * 0.84,
      ),
      3.67,
      2.8,
    );
  canvas.drawPath(
    rimPath,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.50 * opacity),
  );
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

/// スライム: 鮮やかなグリーン + リムSSS + グリッター + 複数スペキュラー（Canvas フォールバック）。
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

  // ベース（鮮やかな半透明グリーン）
  final basePaint = Paint()
    ..color = colors.onSurface.withValues(alpha: 0.88 * opacity);
  canvas.drawRRect(rrect, basePaint);

  // 中央 SSS（中心から mint が滲む）
  final sssCenterPaint = Paint()
    ..shader = RadialGradient(
      radius: 0.65,
      colors: [
        colors.glowColor.withValues(alpha: 0.38 * opacity),
        Colors.transparent,
      ],
    ).createShader(rect);
  canvas.drawRRect(rrect, sssCenterPaint);

  // リム SSS（エッジから明るいライム光が入る）
  final sssRimPaint = Paint()
    ..shader = RadialGradient(
      radius: 1,
      colors: [
        Colors.transparent,
        colors.glowColor.withValues(alpha: 0.30 * opacity),
      ],
      stops: const [0.60, 1.0],
    ).createShader(rect);
  canvas.drawRRect(rrect, sssRimPaint);

  // ウェット表面シーン（左上 — 広いソフト + 小さいコア）
  final sheenSoftPaint = Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.45, -0.52),
      radius: 1,
      colors: [
        Colors.white.withValues(alpha: 0.38 * opacity),
        Colors.white.withValues(alpha: 0),
      ],
    ).createShader(rect);
  canvas.drawRRect(rrect, sheenSoftPaint);

  // プライマリスペキュラー（鋭い白ホットスポット）
  final coreSize = rect.width * 0.12;
  final coreRect = Rect.fromCenter(
    center: Offset(
      rect.left + rect.width * 0.28,
      rect.top + rect.height * 0.22,
    ),
    width: coreSize,
    height: coreSize * 0.65,
  );
  canvas.drawOval(
    coreRect,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.88 * opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
  );
}

/// ノイズブロックを描画する。
///
/// テーマカラーのベースブロックの上に×チェーン背景・HP数字・錠前アイコンを重ねる。
/// [style] と [colors] はベースブロックの描画に使用する。
/// [hp] は現在のHP（1〜[maxHp]）。[damageFlash] は 0〜1 のダメージフラッシュ強度。
void drawNoiseCell(
  Canvas canvas,
  Rect rect,
  int hp,
  int maxHp,
  GameThemeCellStyle style,
  GameThemeColors colors, {
  double damageFlash = 0.0,
  FragmentShader? shader,
  double shaderTime = 0.0,
}) {
  // ① ベースブロック（テーマカラーそのまま）
  drawCell(canvas, rect, style, colors, shader: shader, time: shaderTime);

  final rrect = RRect.fromRectAndRadius(
    rect,
    Radius.circular(style.cellBorderRadius),
  );

  // ② 薄い暗オーバーレイ（通常ブロックとの識別）
  canvas.drawRRect(
    rrect,
    Paint()..color = Colors.black.withValues(alpha: 0.22),
  );

  // ③ バッテンチェーン背景（×型の破線）
  _drawChainX(canvas, rect, style.cellBorderRadius);

  // ④ 錠前アイコン（下部寄り）
  _drawLockIcon(canvas, rect);

  // ⑤ HP 数字（錠前の上部）
  _drawHpNumber(canvas, rect, hp);

  // ⑥ ダメージフラッシュ（白いフラッシュ）
  if (damageFlash > 0) {
    canvas.drawRRect(
      rrect,
      Paint()..color = Colors.white.withValues(alpha: damageFlash * 0.65),
    );
  }
}

/// ×型の破線チェーンを描画する。
void _drawChainX(Canvas canvas, Rect rect, double borderRadius) {
  canvas
    ..save()
    ..clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)));
  final chainPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.28)
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  _drawDashedLine(canvas, rect.topLeft, rect.bottomRight, chainPaint, 4, 3);
  _drawDashedLine(canvas, rect.topRight, rect.bottomLeft, chainPaint, 4, 3);
  canvas.restore();
}

/// 2点間を破線で描画する（チェーン表現用）。
void _drawDashedLine(
  Canvas canvas,
  Offset from,
  Offset to,
  Paint paint,
  double dashLen,
  double gapLen,
) {
  final dx = to.dx - from.dx;
  final dy = to.dy - from.dy;
  final totalLen = sqrt(dx * dx + dy * dy);
  if (totalLen <= 0) {
    return;
  }
  final ux = dx / totalLen;
  final uy = dy / totalLen;

  var t = 0.0;
  var drawing = true;
  while (t < totalLen) {
    final segLen = drawing ? dashLen : gapLen;
    final end = (t + segLen).clamp(0.0, totalLen);
    if (drawing) {
      canvas.drawLine(
        Offset(from.dx + ux * t, from.dy + uy * t),
        Offset(from.dx + ux * end, from.dy + uy * end),
        paint,
      );
    }
    t = end;
    drawing = !drawing;
  }
}

/// 錠前アイコンを白で描画する（数字スペース確保のため下部寄り）。
void _drawLockIcon(Canvas canvas, Rect rect) {
  final cw = rect.width;
  final cx = rect.center.dx;
  // 上部の数字領域を空けるため、錠前を下側に配置
  final bodyCenter = Offset(cx, rect.top + rect.height * 0.64);

  final bodyW = cw * 0.36;
  final bodyH = bodyW * 0.55;
  final bodyLeft = bodyCenter.dx - bodyW / 2;
  final bodyTop = bodyCenter.dy - bodyH / 2;

  const lockAlpha = 0.88;

  // 本体（角丸矩形）
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyLeft, bodyTop, bodyW, bodyH),
      Radius.circular(bodyW * 0.12),
    ),
    Paint()..color = Colors.white.withValues(alpha: lockAlpha),
  );

  // シャックル（半円弧、本体上部から突出）
  final shackleR = bodyW * 0.33;
  canvas
    ..drawArc(
      Rect.fromCenter(
        center: Offset(cx, bodyTop + shackleR * 0.1),
        width: shackleR * 2,
        height: shackleR * 2,
      ),
      pi,  // 左（9時方向）から
      -pi, // 反時計回りで右（上を通る半円）
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: lockAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = bodyW * 0.18
        ..strokeCap = StrokeCap.butt,
    )
    // キーホール（本体中央の小円）
    ..drawCircle(
      Offset(cx, bodyTop + bodyH * 0.42),
      bodyW * 0.1,
      Paint()..color = Colors.black.withValues(alpha: 0.32),
    );
}

/// HP 数字を錠前の上部に描画する。
void _drawHpNumber(Canvas canvas, Rect rect, int hp) {
  final tp = TextPainter(
    text: TextSpan(
      text: '$hp',
      style: TextStyle(
        fontSize: rect.width * 0.30,
        fontWeight: FontWeight.bold,
        color: Colors.white.withValues(alpha: 0.9),
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  tp
    ..layout()
    ..paint(
      canvas,
      Offset(
        rect.center.dx - tp.width / 2,
        rect.top + rect.height * 0.11,
      ),
    )
    ..dispose();
}

/// アイス: 水晶質感 + ファセットライン + フロストエッジ + 内部クラック（Canvas フォールバック）。
void _drawIce(
  Canvas canvas,
  Rect rect,
  GameThemeCellStyle style,
  GameThemeColors colors,
  double opacity,
) {
  final rrect = RRect.fromRectAndRadius(
    rect,
    const Radius.circular(2),
  );

  // ベース（透明感のある水色）
  final basePaint = Paint()
    ..color = colors.onSurface.withValues(alpha: 0.30 * opacity);
  canvas.drawRRect(rrect, basePaint);

  // コースティック風: TL明 → BR暗の斜めグラデ
  final sheenPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.72 * opacity),
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: 0.22 * opacity),
      ],
      stops: const [0.0, 0.28, 0.72, 1.0],
    ).createShader(rect);
  canvas.drawRRect(rrect, sheenPaint);

  // フロストエッジ（縁の霜: シアン白のリムグロー）
  final frostPaint = Paint()
    ..shader = RadialGradient(
      radius: 1,
      colors: [
        Colors.transparent,
        const Color(0xFFD0F0FF).withValues(alpha: 0.45 * opacity),
      ],
      stops: const [0.58, 1.0],
    ).createShader(rect);
  canvas.drawRRect(rrect, frostPaint);

  // 内部クラック（複数本、ランダム）
  final seed = (rect.left * 11 + rect.top * 17).toInt();
  final rng = Random(seed);
  final crackPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.62 * opacity)
    ..strokeWidth = 1;
  final crackCount = 1 + rng.nextInt(3); // 1〜3本
  for (var i = 0; i < crackCount; i++) {
    final p1 = Offset(
      rect.left + rng.nextDouble() * rect.width,
      rect.top + rng.nextDouble() * rect.height,
    );
    final p2 = Offset(
      rect.left + rng.nextDouble() * rect.width,
      rect.top + rng.nextDouble() * rect.height,
    );
    canvas.drawLine(p1, p2, crackPaint);
  }

  // インナーボーダー（氷の厚み表現）＋ アウターエッジ（強い白縁: Fresnel 近似）
  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(1)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.38 * opacity),
    )
    ..drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.62 * opacity),
    );
}
