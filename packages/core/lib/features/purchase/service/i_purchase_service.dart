import 'package:core/features/purchase/model/plan_type.dart';
import 'package:core/features/purchase/model/pricing.dart';

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

  /// 月額プランの商品タイトルを返す。
  ///
  /// App Store / Google Play に登録した商品名。取得できない場合は `null` を返す。
  Future<String?> getMonthlyProductTitle();

  /// 通常・セール両 Offering の価格を 1 回の getOfferings() 呼び出しで取得する。
  Future<Pricing> getPricing();

  /// プランを購入する。
  ///
  /// [sale] が `true` の場合は `premium_sale` Offering を使用し、
  /// 該当 Offering が未設定の場合は通常 Offering にフォールバックする。
  /// ユーザーがキャンセルした場合は何もしない。エラー時は例外をスローする。
  Future<void> purchase(PlanType plan, {bool sale = false});

  /// 過去の購入を復元し、プレミアム状態かどうかを返す。
  Future<bool> restorePurchases();

  /// プレミアムの次回更新日（または有効期限）を "yyyy年MM月dd日" 形式で返す。
  ///
  /// 買い切りや取得できない場合は `null` を返す。
  Future<String?> getExpirationDateString();

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
