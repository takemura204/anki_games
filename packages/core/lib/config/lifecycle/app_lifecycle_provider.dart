import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appLifecycleProvider =
    NotifierProvider<AppLifecycleNotifier, AppLifecycleData>(
      AppLifecycleNotifier.new,
    );

class AppLifecycleData {
  const AppLifecycleData({
    this.backgroundedAt,
    this.lastAdShownAt,
    this.lastResultAdShownAt,
    this.lastBgDuration,
  });

  final DateTime? backgroundedAt;
  final DateTime? lastAdShownAt;

  /// 結果ページ広告の最終表示時刻（BG広告とは独立したクールダウン）。
  final DateTime? lastResultAdShownAt;

  /// 直前のバックグラウンド滞在時間。フォアグラウンド復帰時に設定される。
  /// リスナー（QuizScreen 等）がこの値の変化を検知して学習時間補正を行う。
  final Duration? lastBgDuration;

  static const _sentinel = Object();

  AppLifecycleData copyWith({
    Object? backgroundedAt = _sentinel,
    Object? lastAdShownAt = _sentinel,
    Object? lastResultAdShownAt = _sentinel,
    Object? lastBgDuration = _sentinel,
  }) {
    return AppLifecycleData(
      backgroundedAt: backgroundedAt == _sentinel
          ? this.backgroundedAt
          : backgroundedAt as DateTime?,
      lastAdShownAt: lastAdShownAt == _sentinel
          ? this.lastAdShownAt
          : lastAdShownAt as DateTime?,
      lastResultAdShownAt: lastResultAdShownAt == _sentinel
          ? this.lastResultAdShownAt
          : lastResultAdShownAt as DateTime?,
      lastBgDuration: lastBgDuration == _sentinel
          ? this.lastBgDuration
          : lastBgDuration as Duration?,
    );
  }
}

class AppLifecycleNotifier extends Notifier<AppLifecycleData> {
  static const _prefsKey = 'last_interstitial_shown_at';
  static const _resultPrefsKey = 'last_result_interstitial_shown_at';

  @override
  AppLifecycleData build() {
    _loadPersistedDates();
    return const AppLifecycleData();
  }

  Future<void> _loadPersistedDates() async {
    final prefs = await SharedPreferences.getInstance();
    final adMillis = prefs.getInt(_prefsKey);
    final resultMillis = prefs.getInt(_resultPrefsKey);
    state = state.copyWith(
      lastAdShownAt: adMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(adMillis)
          : null,
      lastResultAdShownAt: resultMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(resultMillis)
          : null,
    );
  }

  void onPaused() {
    state = state.copyWith(backgroundedAt: DateTime.now());
  }

  /// フォアグラウンド復帰時に呼ぶ。
  /// `lastBgDuration` に滞在時間を設定する。
  /// paused を経由しない場合（コールドスタート等）は何もしない。
  void onResumed() {
    final bg = state.backgroundedAt;
    if (bg == null) return;
    final duration = DateTime.now().difference(bg);
    state = state.copyWith(backgroundedAt: null, lastBgDuration: duration);
  }

  void recordAdShown() {
    final now = DateTime.now();
    state = state.copyWith(lastAdShownAt: now);
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setInt(_prefsKey, now.millisecondsSinceEpoch),
    );
  }

  void recordResultAdShown() {
    final now = DateTime.now();
    // resume ベースのクールダウン (lastAdShownAt) も同時に更新する。
    // 結果ページ広告の表示直後に resume イベントが発火した場合に
    // 二重表示されるのを防ぐ。
    state = state.copyWith(lastResultAdShownAt: now, lastAdShownAt: now);
    SharedPreferences.getInstance().then((prefs) {
      prefs
        ..setInt(_resultPrefsKey, now.millisecondsSinceEpoch)
        ..setInt(_prefsKey, now.millisecondsSinceEpoch);
    });
  }

  void resetCooldowns() {
    state = state.copyWith(lastAdShownAt: null, lastResultAdShownAt: null);
    SharedPreferences.getInstance().then((prefs) {
      prefs
        ..remove(_prefsKey)
        ..remove(_resultPrefsKey);
    });
    debugPrint('[AdInterstitial] クールダウンをリセットしました');
  }
}
