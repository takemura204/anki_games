enum HomeGameKind {
  blockPuzzle,
}

extension HomeGameKindStorage on HomeGameKind {
  String get storageValue => switch (this) {
        HomeGameKind.blockPuzzle => 'block',
      };

  int get pageIndex => switch (this) {
        HomeGameKind.blockPuzzle => 0,
      };
}

HomeGameKind homeGameKindFromStorage(String? raw) {
  return HomeGameKind.blockPuzzle;
}

const kPrefHomeSelectedGame = 'home_selected_game';
const kPrefLastGameKind = 'last_game_kind';
