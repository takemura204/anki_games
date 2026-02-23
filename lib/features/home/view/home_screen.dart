import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/noir_mind/view/noir_mind_screen.dart';
import 'package:mono_games/features/noir_mind/view_model/noir_mind_view_model.dart';
import 'package:mono_games/features/noir_mind/view_model/quest_progress_view_model.dart';
import 'package:mono_games/features/settings/view/settings_dialog.dart';
import 'package:mono_games/i18n/translations.g.dart';

part 'widgets/home_widget.dart';

/// The home screen displaying a list of available games.
class HomeScreen extends ConsumerWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: _HomeWidget());
  }
}
