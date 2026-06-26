import 'dart:math';

import 'package:flutter/material.dart';

/// 円弧が伸びた後にチェックマークが描かれる CustomPainter。
/// ResultPage とストリークドットで共用する。
class CheckmarkPainter extends CustomPainter {
  const CheckmarkPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 5,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    final arcProgress = (progress * 1.4).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * arcProgress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0.5) {
      final checkProgress = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      final startPoint = Offset(size.width * 0.24, size.height * 0.5);
      final midPoint = Offset(size.width * 0.44, size.height * 0.68);
      final endPoint = Offset(size.width * 0.76, size.height * 0.33);

      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      if (checkProgress < 0.5) {
        final t = checkProgress * 2;
        final current = Offset.lerp(startPoint, midPoint, t)!;
        path
          ..moveTo(startPoint.dx, startPoint.dy)
          ..lineTo(current.dx, current.dy);
      } else {
        final t = (checkProgress - 0.5) * 2;
        final current = Offset.lerp(midPoint, endPoint, t)!;
        path
          ..moveTo(startPoint.dx, startPoint.dy)
          ..lineTo(midPoint.dx, midPoint.dy)
          ..lineTo(current.dx, current.dy);
      }
      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(CheckmarkPainter old) => old.progress != progress;
}
