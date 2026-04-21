import 'package:app_block_puzzle/router/modal_sheet_router.dart';
import 'package:core/features/quiz/view_model/quiz_view_model.dart';
import 'package:core/utils/router/router_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../block_puzzle/view_model/block_puzzle_view_model.dart';
import '../model/home_game_kind.dart';
import 'home_game_mode_provider.dart';

class HomeState {
  const HomeState({this.isLoading = true});

  final bool isLoading;

  HomeState copyWith({bool? isLoading}) =>
      HomeState(isLoading: isLoading ?? this.isLoading);
}

final NotifierProvider<HomeViewModel, HomeState> homeViewModelProvider =
    NotifierProvider.autoDispose<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    final link = ref.keepAlive();
    Future<void>.microtask(() async {
      await _onLoad();
      link.close();
    });
    return const HomeState();
  }

  Future<void> _onLoad() async {
    await ref
        .read(blockPuzzleViewModelProvider.notifier)
        .ensurePersistedDataLoaded();
    await ref.read(quizViewModelProvider.notifier).loadMasteryStats();

    final initialLevelKey = ref.read(initialLevelKeyProvider);
    await ref.read(homeGameModeProvider.notifier).loadFromPrefs();

    if (initialLevelKey != null) {
      await _restoreGame(initialLevelKey);
      return;
    }
    state = state.copyWith(isLoading: false);
  }

  Future<void> _restoreGame(String levelKey) async {
    final match = LevelFilter.values.where((l) => l.name == levelKey);
    if (match.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    final level = match.first;
    final prefs = await SharedPreferences.getInstance();

    await ref.read(quizViewModelProvider.notifier).setLevelFilter(level);
    ref.read(blockPuzzleViewModelProvider.notifier).startQuizMode(level);
    ref.read(quizViewModelProvider.notifier).resetSession();

    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      state = state.copyWith(isLoading: false);
      return;
    }
    await ctx.push<void>(ScreenRoutes.game);

    await prefs.setBool('was_on_puzzle_screen', false);
    await ref.read(quizViewModelProvider.notifier).loadMasteryStats();
    state = state.copyWith(isLoading: false);
  }

  Future<void> onLevelCardTap(LevelFilter level) async {
    await ref.read(quizViewModelProvider.notifier).setLevelFilter(level);

    final shouldStart =
        await ref.read(modalSheetRouterProvider).showQuizStart(level);
    if (!shouldStart) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool('was_on_puzzle_screen', true),
      prefs.setString('last_level_key', level.name),
      prefs.setString(kPrefLastGameKind, HomeGameKind.blockPuzzle.storageValue),
    ]);

    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      return;
    }
    await ctx.push<void>(ScreenRoutes.game);

    await prefs.setBool('was_on_puzzle_screen', false);
    await ref.read(quizViewModelProvider.notifier).loadMasteryStats();
  }

  void onSettingsTap() {
    ref.read(modalSheetRouterProvider).showHomeSettings();
  }
}
