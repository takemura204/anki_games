import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../model/game_theme.dart';

/// テーマ別背景エフェクトウィジェット。
class BackgroundEffectWidget extends StatelessWidget {
  /// 背景エフェクトウィジェットを作成する。
  const BackgroundEffectWidget({required this.theme, super.key});

  /// 現在のゲームテーマ。
  final GameTheme theme;

  @override
  Widget build(BuildContext context) {
    final bg = theme.background;
    final themeColors = theme.colorsFor(Theme.of(context).brightness);

    return switch (bg.mode) {
      BackgroundMode.solid => const SizedBox.shrink(),
      BackgroundMode.cyberGrid => _CyberGridBackground(
          gridLineColor: bg.gridLineColor ?? themeColors.gridLine,
          scrollSpeed: bg.gridScrollSpeed,
          scanlineOpacity: bg.scanlineOpacity,
        ),
      BackgroundMode.gradient => _GradientBackground(
          colors: bg.gradientColors,
        ),
      BackgroundMode.paperTexture => _PaperTextureBackground(
          surfaceColor: themeColors.surface,
          noiseOpacity: bg.noiseOpacity,
        ),
    };
  }
}

// --- Cyber Grid ---

class _CyberGridBackground extends StatefulWidget {
  const _CyberGridBackground({
    required this.gridLineColor,
    required this.scrollSpeed,
    required this.scanlineOpacity,
  });

  final Color gridLineColor;
  final double scrollSpeed;
  final double scanlineOpacity;

  @override
  State<_CyberGridBackground> createState() => _CyberGridBackgroundState();
}

class _CyberGridBackgroundState extends State<_CyberGridBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _CyberGridPainter(
            gridLineColor: widget.gridLineColor,
            scrollOffset: _controller.value * widget.scrollSpeed * 10,
            scanlineOpacity: widget.scanlineOpacity,
          ),
        );
      },
    );
  }
}

class _CyberGridPainter extends CustomPainter {
  const _CyberGridPainter({
    required this.gridLineColor,
    required this.scrollOffset,
    required this.scanlineOpacity,
  });

  final Color gridLineColor;
  final double scrollOffset;
  final double scanlineOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    const gridSpacing = 40.0;
    final gridPaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 0.5;

    // 縦線
    for (var x = 0.0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // 横線（スクロール）
    final yStart = (scrollOffset % gridSpacing) - gridSpacing;
    for (var y = yStart; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 走査線
    if (scanlineOpacity > 0) {
      final scanPaint = Paint()
        ..color = Colors.black.withValues(alpha: scanlineOpacity);
      for (var y = 0.0; y < size.height; y += 3) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          scanPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CyberGridPainter oldDelegate) =>
      scrollOffset != oldDelegate.scrollOffset;
}

// --- Gradient ---

class _GradientBackground extends StatelessWidget {
  const _GradientBackground({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    if (colors.length < 2) {
      return const SizedBox.shrink();
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

// --- Paper Texture ---

class _PaperTextureBackground extends StatelessWidget {
  const _PaperTextureBackground({
    required this.surfaceColor,
    required this.noiseOpacity,
  });

  final Color surfaceColor;
  final double noiseOpacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _PaperTexturePainter(
        surfaceColor: surfaceColor,
        noiseOpacity: noiseOpacity,
      ),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter({
    required this.surfaceColor,
    required this.noiseOpacity,
  });

  final Color surfaceColor;
  final double noiseOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    // ベース
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = surfaceColor,
    );

    // ノイズドット（和紙風）
    if (noiseOpacity > 0) {
      final rng = Random(42);
      final dotCount = (size.width * size.height * 0.002).toInt();
      final points = <Offset>[];
      for (var i = 0; i < dotCount; i++) {
        points.add(
          Offset(
            rng.nextDouble() * size.width,
            rng.nextDouble() * size.height,
          ),
        );
      }
      final paint = Paint()
        ..color = Colors.black.withValues(alpha: noiseOpacity)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawPoints(PointMode.points, points, paint);
    }
  }

  @override
  bool shouldRepaint(_PaperTexturePainter oldDelegate) => false;
}
