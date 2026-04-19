import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:anki_games/apps/block_puzzle/features/home/model/home_game_kind.dart';
import 'package:anki_games/common/features/quiz/view_model/quiz_view_model.dart';
import 'package:anki_games/common/until/router/router_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final wordRangeViewModelProvider =
    NotifierProvider.autoDispose<WordRangeViewModel, void>(
  WordRangeViewModel.new,
);

class WordRangeViewModel extends AutoDisposeNotifier<void> {
  @override
  void build() {}

  Future<void> startGame({required LevelFilter? singleLevel}) async {
    final level = singleLevel ?? LevelFilter.eiken5;

    ref.read(quizViewModelProvider.notifier).resetSession();
    ref.read(blockPuzzleViewModelProvider.notifier).startQuizMode(level);

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool('was_on_puzzle_screen', true),
      prefs.setString('last_level_key', level.name),
      prefs.setString(kPrefLastGameKind, HomeGameKind.blockPuzzle.storageValue),
    ]);

    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    await ctx.push<void>(ScreenRoutes.game);

    await prefs.setBool('was_on_puzzle_screen', false);
    await ref.read(quizViewModelProvider.notifier).loadMasteryStats();
  }

  void goBack() {
    rootNavigatorKey.currentContext?.pop();
  }
}
