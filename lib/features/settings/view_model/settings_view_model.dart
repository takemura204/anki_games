import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_view_model.g.dart';

const _soundKey = 'settings_sound_enabled';
const _vibrationKey = 'settings_vibration_enabled';

/// アプリ設定の状態。
class SettingsState {
  /// 設定状態を作成する。
  const SettingsState({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  /// サウンドが有効かどうか。
  final bool soundEnabled;

  /// バイブレーションが有効かどうか。
  final bool vibrationEnabled;

  /// 指定フィールドを置き換えたコピーを返す。
  SettingsState copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) =>
      SettingsState(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      );
}

/// アプリ設定（サウンド・バイブレーション）を管理するビューモデル。
@riverpod
class SettingsViewModel extends _$SettingsViewModel {
  @override
  SettingsState build() {
    _load();
    return const SettingsState();
  }

  void _load() {
    SharedPreferences.getInstance().then((prefs) {
      state = SettingsState(
        soundEnabled: prefs.getBool(_soundKey) ?? true,
        vibrationEnabled: prefs.getBool(_vibrationKey) ?? true,
      );
    });
  }

  /// サウンドの有効/無効を切り替える。
  void toggleSound() {
    final next = !state.soundEnabled;
    state = state.copyWith(soundEnabled: next);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_soundKey, next));
  }

  /// バイブレーションの有効/無効を切り替える。
  void toggleVibration() {
    final next = !state.vibrationEnabled;
    state = state.copyWith(vibrationEnabled: next);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_vibrationKey, next));
  }
}
