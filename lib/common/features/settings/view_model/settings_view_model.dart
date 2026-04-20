import 'package:anki_games/common/features/quiz/view_model/quiz_view_model.dart';
import 'package:anki_games/common/utils/router/modal_router.dart';
import 'package:anki_games/common/utils/router/router_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  /// 学習データの削除確認ダイアログを表示し、承認されたら全データを削除して設定シートを閉じる。
  Future<void> onDeleteLearningData() async {
    final confirmed =
        await ref.read(modalRouterProvider).showDeleteLearningDataConfirm();
    if (!confirmed) {
      return;
    }
    await ref.read(quizViewModelProvider.notifier).deleteAllLearningData();
    rootNavigatorKey.currentContext?.pop();
  }

  /// ゲーム画面の設定シートからホーム画面に戻る。
  /// 設定シート自体は GoRouter の pop で閉じつつ、ゲーム画面も同時に pop する。
  void goHome() {
    // 設定シートはモーダルルートなので Navigator.pop で閉じてから
    // GoRouter で game ルートを pop してホームに戻る。
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) {
      return;
    }
    // popUntil でルートスタックの最初（HomeScreen）まで戻る
    Navigator.of(ctx).popUntil((Route<dynamic> route) => route.isFirst);
  }
}
