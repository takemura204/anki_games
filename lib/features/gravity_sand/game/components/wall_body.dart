import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

/// A static wall created from a finger drag gesture.
/// Fades out over [lifetime] seconds then removes itself.
class WallBody extends BodyComponent with ContactCallbacks {
  /// Creates a wall from a list of [points] in world coordinates.
  WallBody({required this.points, required this.createdAt});

  /// Points defining the wall segments in world coordinates.
  final List<Vector2> points;

  /// Game time when this wall was created.
  final double createdAt;

  /// How long the wall lasts before disappearing.
  static const double lifetime = 5;

  /// Stroke width in world units.
  static const double _strokeWidth = 0.15;

  double _opacity = 1;

  @override
  Body createBody() {
    final body = world.createBody(BodyDef())
      ..userData = this;

    for (var i = 0; i < points.length - 1; i++) {
      body.createFixture(
        FixtureDef(
          EdgeShape()..set(points[i], points[i + 1]),
          friction: 0.5,
        ),
      );
    }

    return body;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final age = game.currentTime() - createdAt;
    _opacity = ((lifetime - age) / lifetime).clamp(0, 1).toDouble();
    if (age >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (points.length < 2) return;

    final wallPaint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, _opacity)
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(
        points[i].toOffset(),
        points[i + 1].toOffset(),
        wallPaint,
      );
    }
  }
}
