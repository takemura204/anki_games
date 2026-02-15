import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:mono_games/features/gravity_sand/game/gravity_sand_game.dart';

/// A single sand grain represented as a small dynamic circle body.
class SandParticle extends BodyComponent<GravitySandGame>
    with ContactCallbacks {
  /// Creates a sand particle at the given [initialPosition] in world coords.
  SandParticle({required this.initialPosition});

  /// Spawn position in world coordinates.
  final Vector2 initialPosition;

  /// Radius in world units (0.2m = ~2px at zoom 10).
  static const double radius = 0.2;

  /// Relative speed threshold for triggering haptic feedback.
  static const double _hapticThreshold = 5;

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      type: BodyType.dynamic,
      position: initialPosition,
    );
    final body = world.createBody(bodyDef)
      ..userData = this;

    final fixtureDef = FixtureDef(
      CircleShape()..radius = radius,
      restitution: 0.1,
    );
    body.createFixture(fixtureDef);

    return body;
  }

  @override
  void beginContact(Object other, Contact contact) {
    super.beginContact(other, contact);
    final vA = contact.bodyA.linearVelocity;
    final vB = contact.bodyB.linearVelocity;
    if ((vA - vB).length > _hapticThreshold) {
      game.triggerHaptic();
    }
  }
}
