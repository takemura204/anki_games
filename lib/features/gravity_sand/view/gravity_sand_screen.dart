import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/gravity_sand/game/gravity_sand_game.dart';

/// Screen hosting the Gravity Sand Forge2D game.
class GravitySandScreen extends HookConsumerWidget {
  /// Creates the Gravity Sand screen.
  const GravitySandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = useRef(GravitySandGame());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GameWidget(game: game.value),
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
