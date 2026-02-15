import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/gravity_sand/view/gravity_sand_screen.dart';
import 'package:mono_games/features/noir_mind/view/noir_mind_screen.dart';
import 'package:mono_games/i18n/translations.g.dart';

part 'widgets/home_widget.dart';

/// The home screen displaying a list of available games.
class HomeScreen extends HookConsumerWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(t.home.title)),
      body: const _HomeWidget(),
    );
  }
}
