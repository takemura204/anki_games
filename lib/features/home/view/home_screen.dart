import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/home/view_model/home_view_model.dart';

part 'widgets/home_widget.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(homeViewModelProvider);
    final vm = ref.read(homeViewModelProvider.notifier);
    return const Scaffold(body: _HomeWidget());
  }
}
