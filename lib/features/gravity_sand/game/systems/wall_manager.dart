import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:mono_games/features/gravity_sand/game/components/wall_body.dart';
import 'package:mono_games/features/gravity_sand/game/gravity_sand_game.dart';

/// Handles drag input to create wall bodies from finger gestures.
class WallManager extends Component with HasGameReference<GravitySandGame>, DragCallbacks {
  /// Minimum distance between consecutive wall points (world units).
  static const double _minSegmentLength = 0.5;

  List<Vector2>? _currentPoints;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final worldPos = game.screenToWorld(event.canvasPosition);
    _currentPoints = [worldPos];
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_currentPoints == null) {
      return;
    }
    final worldPos = game.screenToWorld(event.canvasEndPosition);
    if (_currentPoints!.last.distanceTo(worldPos) >= _minSegmentLength) {
      _currentPoints!.add(worldPos);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_currentPoints != null && _currentPoints!.length >= 2) {
      game.world.add(
        WallBody(
          points: List.of(_currentPoints!),
          createdAt: game.currentTime(),
        ),
      );
    }
    _currentPoints = null;
  }
}
