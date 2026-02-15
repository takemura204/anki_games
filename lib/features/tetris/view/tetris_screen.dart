import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/tetris/model/tetris_model.dart';
import 'package:mono_games/features/tetris/view_model/tetris_view_model.dart';

part 'widgets/tetris_widget.dart';

class TetrisScreen extends HookConsumerWidget {
  const TetrisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(tetrisViewModelProvider);
    final vm = ref.read(tetrisViewModelProvider.notifier);
    final d = ref.watch(tetrisModelProvider);
    final m = ref.read(tetrisModelProvider.notifier);
    return const Scaffold(body: _TetrisWidget());
  }
}
