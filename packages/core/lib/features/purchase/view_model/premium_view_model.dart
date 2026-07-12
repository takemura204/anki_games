import 'package:core/features/purchase/model/plan_type.dart';
import 'package:core/features/purchase/model/pricing.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/i_purchase_service.dart';

part 'premium_view_model.g.dart';

/// 課金サービスのプロバイダ。main.dart で [IPurchaseService] 実装に override する。
@Riverpod(keepAlive: true)
IPurchaseService purchaseService(Ref ref) {
  throw UnimplementedError(
    'purchaseServiceProvider must be overridden in main',
  );
}

/// 月額プランの商品タイトルプロバイダ。
@riverpod
Future<String?> monthlyTitle(Ref ref) async {
  await ref.watch(premiumViewModelProvider.future);
  return ref.read(purchaseServiceProvider).getMonthlyProductTitle();
}

/// 通常・セール両 Offering の価格を一括取得するプロバイダ。
///
/// RevenueCat の `getOfferings()` を 1 回だけ呼び出し [Pricing] モデルを返す。
final FutureProvider<Pricing> pricingProvider = FutureProvider<Pricing>(
  (ref) async {
    await ref.watch(premiumViewModelProvider.future);
    return ref.read(purchaseServiceProvider).getPricing();
  },
);

/// プレミアムの次回更新日文字列プロバイダ（例: "2026年6月9日"）。
///
/// 買い切りや非プレミアムの場合は `null`。
@riverpod
Future<String?> premiumExpirationDate(Ref ref) async {
  await ref.watch(premiumViewModelProvider.future);
  return ref.read(purchaseServiceProvider).getExpirationDateString();
}

/// プレミアム状態を表す値オブジェクト。
class PremiumState {
  /// プレミアム状態を作成する。
  const PremiumState({this.isPremium = false});

  /// プレミアム会員かどうか。
  final bool isPremium;

  /// 指定フィールドを置き換えたコピーを返す。
  PremiumState copyWith({bool? isPremium}) =>
      PremiumState(isPremium: isPremium ?? this.isPremium);
}

/// プレミアム状態を管理する AsyncNotifier。
///
/// - 初期化時に [IPurchaseService.isPremium] で状態を取得する
/// - [IPurchaseService.addPremiumStatusListener] でリアルタイム更新を受信する
/// - [purchasePlan] / [restore] で購入・復元を実行する
@Riverpod(keepAlive: true)
class PremiumViewModel extends _$PremiumViewModel {
  late OnPremiumStatusChanged _listener;

  @override
  Future<PremiumState> build() async {
    final service = ref.read(purchaseServiceProvider);
    await service.configure();

    _listener = (isPremium) {
      state = AsyncData(PremiumState(isPremium: isPremium));
    };
    service.addPremiumStatusListener(_listener);
    ref.onDispose(() => service.removePremiumStatusListener(_listener));

    final isPremium = await service.isPremium();
    return PremiumState(isPremium: isPremium);
  }

  /// プランを購入する。[sale] が true の場合は premium_sale Offering を使用する。
  ///
  /// 購入完了後はリスナー経由で state が自動更新される。
  /// ユーザーキャンセルは無視し、その他のエラーは例外をスローする。
  Future<void> purchasePlan(PlanType plan, {bool sale = false}) async {
    await ref.read(purchaseServiceProvider).purchase(plan, sale: sale);
  }

  /// 過去の購入を復元する。
  Future<void> restore() async {
    final isPremium =
        await ref.read(purchaseServiceProvider).restorePurchases();
    state = AsyncData(PremiumState(isPremium: isPremium));
  }

  /// デバッグ専用: プレミアム状態をトグルする。
  Future<void> toggleMockPremium() async {
    await ref.read(purchaseServiceProvider).toggleMockPremium();
  }

  /// デバッグ専用: プレミアム状態を直接 true にセットする。
  void debugSetPremium() {
    state = const AsyncData(PremiumState(isPremium: true));
  }
}
