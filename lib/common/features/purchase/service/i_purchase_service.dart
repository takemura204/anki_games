/// プレミアム状態変化コールバックの型エイリアス。
// ignore: avoid_positional_boolean_parameters
typedef OnPremiumStatusChanged = void Function(bool isPremium);

/// 課金サービスの抽象インターフェース。
///
/// デバッグ用モックと RevenueCat 実装の2実装を切り替えるための契約を定義する。
abstract class IPurchaseService {
  /// SDK を初期化する。アプリ起動時に1度だけ呼ぶ。
  Future<void> configure();

  /// 現在のユーザーがプレミアム会員かどうかを返す。
  ///
  /// ネットワークエラーなど取得に失敗した場合は `false` を返す。
  Future<bool> isPremium();

  /// 月額プランの価格文字列（例: "¥480"）を返す。
  ///
  /// 取得できない場合は `null` を返す。
  Future<String?> getMonthlyPriceString();

  /// 月額プランの商品タイトルを返す。
  ///
  /// App Store / Google Play に登録した商品名。取得できない場合は `null` を返す。
  Future<String?> getMonthlyProductTitle();

  /// 月額プランを購入する。
  ///
  /// ユーザーがキャンセルした場合は何もしない。
  /// エラー時は例外をスローする。
  Future<void> purchaseMonthly();

  /// 過去の購入を復元し、プレミアム状態かどうかを返す。
  Future<bool> restorePurchases();

  /// プレミアム状態が変化したときに呼ばれるリスナーを登録する。
  void addPremiumStatusListener(OnPremiumStatusChanged listener);

  /// 登録済みのリスナーを解除する。
  void removePremiumStatusListener(OnPremiumStatusChanged listener);

  /// 将来のログイン機能用スタブ。ユーザーIDを RevenueCat に紐付ける。
  Future<void> logIn(String userId);

  /// 将来のログイン機能用スタブ。RevenueCat のユーザーIDを匿名にリセットする。
  Future<void> logOut();

  /// デバッグ専用: プレミアム状態をトグルする。
  ///
  /// 本番実装では何もしない。
  Future<void> toggleMockPremium();
}
