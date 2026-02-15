import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_forge2d/forge2d_world.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Reads accelerometer data and maps it to the Forge2D world gravity.
/// Falls back to default downward gravity when sensor is unavailable.
class AccelerometerHandler extends Component {
  /// Creates a handler that updates gravity on [forge2dWorld].
  AccelerometerHandler({required this.forge2dWorld});

  /// The Forge2D world whose gravity will be updated.
  final Forge2DWorld forge2dWorld;

  StreamSubscription<AccelerometerEvent>? _subscription;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _subscription = accelerometerEventStream(
        samplingPeriod: SensorInterval.gameInterval,
      ).listen(_onAccelerometerEvent);
    } on Exception {
      // Sensor unavailable (simulator/desktop). Keep default gravity.
    }
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Accelerometer x: lateral tilt, y: forward/back tilt
    // Map to world gravity: tilt right -> gravity right, tilt forward -> down
    forge2dWorld.gravity = Vector2(-event.x, event.y);
  }

  @override
  void onRemove() {
    _subscription?.cancel();
    super.onRemove();
  }
}
