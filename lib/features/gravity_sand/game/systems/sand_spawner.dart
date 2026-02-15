import 'dart:math';

import 'package:flame/components.dart';
import 'package:mono_games/features/gravity_sand/game/components/sand_particle.dart';
import 'package:mono_games/features/gravity_sand/game/gravity_sand_game.dart';

/// Spawns sand particles from the top of the screen at a steady rate.
///
/// Coordinate system: top-left = (0,0), Y increases downward.
/// Particles spawn at Y=0 (top edge) with random X.
class SandSpawner extends Component with HasGameReference<GravitySandGame> {
  /// Maximum number of particles allowed.
  static const int maxParticles = 500;

  /// Seconds between each spawn.
  static const double _spawnInterval = 0.05;

  final _random = Random();
  double _timer = 0;
  int _particleCount = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
    if (_timer >= _spawnInterval && _particleCount < maxParticles) {
      _timer = 0;
      _particleCount++;

      final worldWidth = game.size.x / game.camera.viewfinder.zoom;
      final x = _random.nextDouble() * worldWidth;
      // Spawn at top of screen (Y=0)
      final spawnPos = Vector2(x, 0);

      game.world.add(SandParticle(initialPosition: spawnPos));
    }
  }
}
