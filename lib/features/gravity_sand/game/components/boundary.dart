import 'package:flame_forge2d/flame_forge2d.dart';

/// Static edge bodies forming the screen boundaries.
/// No top wall so particles can spawn from above.
///
/// Coordinate system: top-left = (0,0), Y increases downward.
class Boundary extends BodyComponent {
  /// Creates boundary walls from the given world [screenSize].
  Boundary({required this.screenSize});

  /// The world-coordinate size of the screen.
  final Vector2 screenSize;

  @override
  Body createBody() {
    final w = screenSize.x;
    final h = screenSize.y;

    const friction = 0.3;

    final body = world.createBody(BodyDef())
      // Bottom
      ..createFixture(
        FixtureDef(EdgeShape()..set(Vector2(0, h), Vector2(w, h)))
          ..friction = friction,
      )
      // Left
      ..createFixture(
        FixtureDef(EdgeShape()..set(Vector2.zero(), Vector2(0, h)))
          ..friction = friction,
      )
      // Right
      ..createFixture(
        FixtureDef(EdgeShape()..set(Vector2(w, 0), Vector2(w, h)))
          ..friction = friction,
      );

    return body;
  }
}
