import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/services.dart';
import 'package:mono_games/features/gravity_sand/game/components/boundary.dart';
import 'package:mono_games/features/gravity_sand/game/systems/accelerometer_handler.dart';
import 'package:mono_games/features/gravity_sand/game/systems/sand_spawner.dart';
import 'package:mono_games/features/gravity_sand/game/systems/wall_manager.dart';

/// The main Forge2D game for the Gravity Sand experience.
///
/// Coordinate system: top-left = (0,0), Y increases downward.
/// Zoom = 10 means 10 pixels = 1 world unit.
class GravitySandGame extends Forge2DGame {
  /// Creates the game with default downward gravity and zoom of 10.
  GravitySandGame() : super(gravity: Vector2(0, 10), zoom: 10);

  DateTime _lastHaptic = DateTime.now();

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set camera anchor to top-left so (0,0) is the top-left of the screen
    camera.viewfinder.anchor = Anchor.topLeft;

    final worldSize = Vector2(
      size.x / camera.viewfinder.zoom,
      size.y / camera.viewfinder.zoom,
    );

    // Add boundary walls and systems to the world
    world
      ..add(Boundary(screenSize: worldSize))
      ..add(SandSpawner())
      ..add(WallManager());

    // Accelerometer updates gravity on the world directly
    add(AccelerometerHandler(forge2dWorld: world));
  }

  /// Triggers light haptic feedback, throttled to max 10/sec.
  void triggerHaptic() {
    final now = DateTime.now();
    if (now.difference(_lastHaptic).inMilliseconds < 100) {
      return;
    }
    _lastHaptic = now;
    HapticFeedback.lightImpact();
  }
}
