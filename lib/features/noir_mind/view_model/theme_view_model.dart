import 'package:mono_games/features/noir_mind/model/game_theme.dart';
import 'package:mono_games/features/noir_mind/model/game_themes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_view_model.g.dart';

const _themeKey = 'noir_mind_theme';

/// Noir Mindのテーマ状態を管理するビューモデル。
@riverpod
class ThemeViewModel extends _$ThemeViewModel {
  @override
  GameTheme build() {
    _loadSaved();
    return stoneTheme;
  }

  /// テーマを選択して永続化する。
  void selectTheme(String themeId) {
    state = getThemeById(themeId);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_themeKey, themeId);
    });
  }

  /// 保存済みテーマを非同期で読み込む。
  void _loadSaved() {
    SharedPreferences.getInstance().then((prefs) {
      final savedId = prefs.getString(_themeKey);
      if (savedId != null) {
        state = getThemeById(savedId);
      }
    });
  }
}
