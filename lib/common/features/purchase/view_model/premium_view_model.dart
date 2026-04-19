import 'package:anki_games/common/features/purchase/service/i_purchase_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'premium_view_model.g.dart';

/// 課金サービスのプロバイダ。main.dart で [IPurchaseService] 実装に override する。
@Riverpod(keepAlive: true)
IPurchaseService purchaseService(PurchaseServiceRef ref) {
  throw UnimplementedError(
    'purchaseServiceProvider must be overridden in main',
  );
}

/// 月額プランの価格文字列プロバイダ（例: "¥480"）。
@riverpod
Future<String?> monthlyPrice(MonthlyPriceRef ref) =>
    ref.watch(purchaseServiceProvider).getMonthlyPriceString();

/// 月額プランの商品タイトルプロバイダ。
@riverpod
Future<String?> monthlyTitle(MonthlyTitleRef ref) =>
    ref.watch(purchaseServiceProvider).getMonthlyProductTitle();

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
/// - [purchase] / [restore] で購入・復元を実行する
@Riverpod(keepAlive: true)
class PremiumViewModel extends _$PremiumViewModel {
  late OnPremiumStatusChanged _listener;

  @override
  Future<PremiumState> build() async {
    final service = ref.read(purchaseServiceProvider);

    _listener = (isPremium) {
      state = AsyncData(PremiumState(isPremium: isPremium));
    };
    service.addPremiumStatusListener(_listener);
    ref.onDispose(() => service.removePremiumStatusListener(_listener));

    final isPremium = await service.isPremium();
    return PremiumState(isPremium: isPremium);
  }

  /// 月額プランを購入する。
  ///
  /// 購入完了後はリスナー経由で state が自動更新される。
  /// ユーザーキャンセルは無視し、その他のエラーは例外をスローする。
  Future<void> purchase() async {
    await ref.read(purchaseServiceProvider).purchaseMonthly();
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
}
