import 'package:core/config/ads/ad_config.dart';
import 'package:core/config/lifecycle/app_lifecycle_provider.dart';
import 'package:core/features/admob/admob_interstitial.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void useWidgetLifecycleObserver(BuildContext context, WidgetRef ref) {
  return use(_WidgetObserver(context, ref));
}

class _WidgetObserver extends Hook<void> {
  const _WidgetObserver(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  @override
  HookState<void, Hook<void>> createState() {
    return _WidgetObserverState(ref);
  }
}

class _WidgetObserverState extends HookState<void, _WidgetObserver>
    with WidgetsBindingObserver {
  _WidgetObserverState(this.ref);
  final WidgetRef ref;

  static const _minBgForAd =
      kDebugMode ? Duration(seconds: 3) : Duration(seconds: 60);
  static const _adCooldown = Duration(minutes: 10);

  @override
  void build(BuildContext context) {}

  @override
  void initHook() {
    super.initHook();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        ref.read(appLifecycleProvider.notifier).onPaused();
      case AppLifecycleState.resumed:
        _onResumed();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  void _onResumed() {
    ref.read(appLifecycleProvider.notifier).onResumed();

    final bg = ref.read(appLifecycleProvider).lastBgDuration;
    debugPrint('[AdInterstitial] resumed: lastBgDuration=$bg, minBgForAd=$_minBgForAd');
    if (bg == null) {
      debugPrint('[AdInterstitial] skipped: backgroundedAt が未設定 (cold start等)');
      return;
    }

    _maybeShowInterstitial(bg);
  }

  void _maybeShowInterstitial(Duration bg) {
    if (bg < _minBgForAd) {
      debugPrint('[AdInterstitial] skipped: BG時間不足 (bg=${bg.inSeconds}s < min=${_minBgForAd.inSeconds}s)');
      return;
    }

    final isPremium =
        ref.read(premiumViewModelProvider).asData?.value.isPremium ?? false;
    if (isPremium) {
      debugPrint('[AdInterstitial] skipped: プレミアムユーザー');
      return;
    }

    final last = ref.read(appLifecycleProvider).lastAdShownAt;
    final now = DateTime.now();
    final elapsed = last != null ? now.difference(last) : null;
    final cooldownPassed = last == null || elapsed! >= _adCooldown;
    if (!cooldownPassed) {
      debugPrint('[AdInterstitial] skipped: クールダウン中 (残り${(_adCooldown - elapsed).inSeconds}s)');
      return;
    }

    debugPrint('[AdInterstitial] ✅ loadAndShow() 呼び出し (unitId=${ref.read(adConfigProvider).interstitial})');
    ref.read(appLifecycleProvider.notifier).recordAdShown();
    AdmobInterstitial(ref.read(adConfigProvider)).loadAndShow();
  }
}
