import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/home_game_kind.dart';

final homeGameModeProvider =
    NotifierProvider<HomeGameModeNotifier, HomeGameKind>(
  HomeGameModeNotifier.new,
);

class HomeGameModeNotifier extends Notifier<HomeGameKind> {
  @override
  HomeGameKind build() => HomeGameKind.blockPuzzle;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = homeGameKindFromStorage(prefs.getString(kPrefHomeSelectedGame));
  }

  Future<void> setKind(HomeGameKind kind) async {
    state = kind;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefHomeSelectedGame, kind.storageValue);
  }
}
