/// RevenueCat から取得した通常・セール価格を保持するモデル。
///
/// `getPricing()` で `getOfferings()` を 1 回呼び出して構築する。
class Pricing {
  const Pricing({
    this.monthlyNormal,
    this.monthlySale,
    this.monthlySalePerDay,
    this.lifetimeNormal,
    this.lifetimeSale,
    this.monthlyDiscountPercent,
    this.lifetimeDiscountAmount,
    this.saleMonthlyFound = false,
    this.saleLifetimeFound = false,
    this.debugLifetimeNormalProductId,
    this.debugLifetimeSaleProductId,
    this.debugLifetimeNormalRawPrice,
    this.debugLifetimeSaleRawPrice,
  });

  /// 通常月額価格（例: ¥450）。
  final String? monthlyNormal;

  /// セール月額価格（例: ¥400）。premium_sale Offering の価格。
  final String? monthlySale;

  /// セール月額の 1 日あたり換算（price/30）。
  final String? monthlySalePerDay;

  /// 通常買い切り価格（例: ¥1,980）。
  final String? lifetimeNormal;

  /// セール買い切り価格（例: ¥1,580）。premium_sale Offering の価格。
  final String? lifetimeSale;

  /// 月額の割引率（例: 33 = 33% OFF）。割引なしの場合は null。
  final int? monthlyDiscountPercent;

  /// 買い切りの割引額文字列（例: "¥400 OFF"）。割引なしの場合は null。
  final String? lifetimeDiscountAmount;

  /// premium_sale Offering から月額パッケージを取得できたか。
  final bool saleMonthlyFound;

  /// premium_sale Offering から買い切りパッケージを取得できたか。
  final bool saleLifetimeFound;

  /// デバッグ用: 通常買い切りとして取得したストア商品 ID。
  final String? debugLifetimeNormalProductId;

  /// デバッグ用: セール買い切りとして取得したストア商品 ID。
  final String? debugLifetimeSaleProductId;

  /// デバッグ用: 通常買い切りの生価格 (double)。
  final double? debugLifetimeNormalRawPrice;

  /// デバッグ用: セール買い切りの生価格 (double)。
  final double? debugLifetimeSaleRawPrice;

  bool get hasMonthlyDiscount => monthlyDiscountPercent != null;

  bool get hasLifetimeDiscount => lifetimeDiscountAmount != null;
}
