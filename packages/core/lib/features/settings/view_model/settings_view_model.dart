import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_view_model.g.dart';

const _soundKey = 'settings_sound_enabled';
const _vibrationKey = 'settings_vibration_enabled';
const _ttsKey = 'settings_tts_enabled';

/// アプリ設定の状態。
class SettingsState {
  /// 設定状態を作成する。
  const SettingsState({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.ttsEnabled = true,
  });

  /// サウンドが有効かどうか。
  final bool soundEnabled;

  /// バイブレーションが有効かどうか。
  final bool vibrationEnabled;

  /// TTS（発音読み上げ）が有効かどうか。
  final bool ttsEnabled;

  /// 指定フィールドを置き換えたコピーを返す。
  SettingsState copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? ttsEnabled,
  }) =>
      SettingsState(
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        ttsEnabled: ttsEnabled ?? this.ttsEnabled,
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
        ttsEnabled: prefs.getBool(_ttsKey) ?? true,
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

  /// TTS（発音読み上げ）の有効/無効を切り替える。
  void toggleTts() {
    final next = !state.ttsEnabled;
    state = state.copyWith(ttsEnabled: next);
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool(_ttsKey, next));
  }
}
