import 'package:core/features/purchase/model/plan_type.dart';
import 'package:core/features/purchase/model/pricing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../model/revenue_cat_config.dart';
import 'i_purchase_service.dart';

const _entitlementId = 'premium';
const _normalOfferingId = 'premium';
const _saleOfferingId = 'premium_sale';

/// RevenueCat を使った本番課金サービス。
///
/// [configure] はアプリ起動時に1度だけ呼ぶこと。
class RealPurchaseService implements IPurchaseService {
  RealPurchaseService(this._config);

  final RevenueCatConfig _config;
  final List<OnPremiumStatusChanged> _listeners = [];

  @override
  Future<void> configure() async {
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.verbose);
    }
    await Purchases.configure(PurchasesConfiguration(_config.apiKey));
    Purchases.addCustomerInfoUpdateListener((info) {
      _notifyListeners(isPremium: _isPremiumFromInfo(info));
    });
  }

  @override
  Future<bool> isPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return _isPremiumFromInfo(info);
    } on Exception catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getMonthlyProductTitle() async {
    try {
      final offerings = await Purchases.getOfferings();
      return _findMonthlyPackage(offerings, _normalOfferingId)
          ?.storeProduct
          .title;
    } on Exception catch (e) {
      debugPrint('[RevenueCat] getMonthlyProductTitle error: $e');
      return null;
    }
  }

  static const _mockPricing = Pricing(
    monthlyNormal: '¥450',
    monthlySale: '¥300',
    monthlySalePerDay: '¥10',
    lifetimeNormal: '¥1,800',
    lifetimeSale: '¥1,500',
    monthlyDiscountPercent: 33,
    lifetimeDiscountAmount: '¥300 OFF',
    saleMonthlyFound: true,
    saleLifetimeFound: true,
    debugLifetimeNormalProductId: 'mock_lifetime_normal',
    debugLifetimeSaleProductId: 'mock_lifetime_sale',
    debugLifetimeNormalRawPrice: 1800,
    debugLifetimeSaleRawPrice: 1500,
  );

  @override
  Future<Pricing> getPricing() async {
    if (kDebugMode) return _mockPricing;
    try {
      final offerings = await Purchases.getOfferings();
      _debugDumpOfferings(offerings);

      final normalMonthly =
          _findMonthlyPackage(offerings, _normalOfferingId)?.storeProduct;
      final normalLifetime =
          _findLifetimePackage(offerings, _normalOfferingId)?.storeProduct;
      final saleMonthly =
          _findMonthlyPackage(offerings, _saleOfferingId)?.storeProduct;
      final saleLifetime =
          _findLifetimePackage(offerings, _saleOfferingId)?.storeProduct;

      String? monthlySalePerDay;
      if (saleMonthly != null) {
        monthlySalePerDay = '¥${(saleMonthly.price / 30).round()}';
      }

      int? monthlyDiscountPercent;
      if (normalMonthly != null &&
          saleMonthly != null &&
          saleMonthly.price < normalMonthly.price) {
        monthlyDiscountPercent =
            ((normalMonthly.price - saleMonthly.price) /
                    normalMonthly.price *
                    100)
                .round();
      }

      String? lifetimeDiscountAmount;
      if (normalLifetime != null &&
          saleLifetime != null &&
          saleLifetime.price < normalLifetime.price) {
        final diff = normalLifetime.price - saleLifetime.price;
        lifetimeDiscountAmount = '¥${diff.round()} OFF';
      }

      return Pricing(
        monthlyNormal: normalMonthly?.priceString,
        monthlySale: saleMonthly?.priceString,
        monthlySalePerDay: monthlySalePerDay,
        lifetimeNormal: normalLifetime?.priceString,
        lifetimeSale: saleLifetime?.priceString,
        monthlyDiscountPercent: monthlyDiscountPercent,
        lifetimeDiscountAmount: lifetimeDiscountAmount,
        saleMonthlyFound: saleMonthly != null,
        saleLifetimeFound: saleLifetime != null,
        debugLifetimeNormalProductId: normalLifetime?.identifier,
        debugLifetimeSaleProductId: saleLifetime?.identifier,
        debugLifetimeNormalRawPrice: normalLifetime?.price,
        debugLifetimeSaleRawPrice: saleLifetime?.price,
      );
    } on Exception catch (e) {
      debugPrint('[RevenueCat] getPricing error: $e');
      return const Pricing();
    }
  }

  @override
  Future<void> purchase(PlanType plan, {bool sale = false}) async {
    final offerings = await Purchases.getOfferings();
    final offeringId = sale ? _saleOfferingId : _normalOfferingId;

    Package? package;
    if (plan == PlanType.monthly) {
      package = _findMonthlyPackage(offerings, offeringId) ??
          (sale ? _findMonthlyPackage(offerings, _normalOfferingId) : null);
    } else {
      package = _findLifetimePackage(offerings, offeringId) ??
          (sale ? _findLifetimePackage(offerings, _normalOfferingId) : null);
    }

    if (package == null) {
      throw Exception(
        '${plan.name} package not available in offering "$offeringId"',
      );
    }
    try {
      await Purchases.purchase(PurchaseParams.package(package));
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return;
      }
      rethrow;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    return _isPremiumFromInfo(info);
  }

  @override
  Future<String?> getExpirationDateString() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final raw = info.entitlements.all[_entitlementId]?.expirationDate;
      if (raw == null) {
        return null;
      }
      final date = DateTime.parse(raw).toLocal();
      return '${date.year}年${date.month}月${date.day}日';
    } on Exception catch (e) {
      debugPrint('[RevenueCat] getExpirationDateString error: $e');
      return null;
    }
  }

  @override
  void addPremiumStatusListener(OnPremiumStatusChanged listener) {
    _listeners.add(listener);
  }

  @override
  void removePremiumStatusListener(OnPremiumStatusChanged listener) {
    _listeners.remove(listener);
  }

  @override
  Future<void> logIn(String userId) => Purchases.logIn(userId);

  @override
  Future<void> logOut() => Purchases.logOut();

  @override
  Future<void> toggleMockPremium() async {}

  bool _isPremiumFromInfo(CustomerInfo info) =>
      info.entitlements.all[_entitlementId]?.isActive ?? false;

  Package? _findMonthlyPackage(Offerings offerings, String offeringId) {
    if (offeringId == _saleOfferingId) {
      return _findPackageById(
        offerings,
        preferOfferingId: _saleOfferingId,
        fallbackOfferingId: _normalOfferingId,
        packageId: _config.premium1mSaleProductId,
      );
    }
    final offering = offerings.all[offeringId];
    if (offering == null) return null;
    // product ID で確定取得。未設定時は offering.monthly にフォールバック。
    return _findPackageByProductId(offering, _config.premium1mProductId) ??
        offering.monthly;
  }

  Package? _findLifetimePackage(Offerings offerings, String offeringId) {
    if (offeringId == _saleOfferingId) {
      return _findPackageById(
        offerings,
        preferOfferingId: _saleOfferingId,
        fallbackOfferingId: _normalOfferingId,
        packageId: _config.premiumLifetimeSaleProductId,
      );
    }
    final offering = offerings.all[offeringId];
    if (offering == null) return null;
    // product ID で確定取得。未設定時は offering.lifetime にフォールバック。
    return _findPackageByProductId(offering, _config.premiumLifetimeProductId) ??
        offering.lifetime;
  }

  /// [preferOfferingId] の Offering にパッケージがなければ [fallbackOfferingId] も探す。
  /// パッケージ ID または ストア商品 ID が [packageId] と一致するものを返す。
  Package? _findPackageById(
    Offerings offerings, {
    required String preferOfferingId,
    required String fallbackOfferingId,
    required String packageId,
  }) {
    for (final offeringId in [preferOfferingId, fallbackOfferingId]) {
      final offering = offerings.all[offeringId];
      if (offering == null) continue;
      final found = _findPackageByProductId(offering, packageId);
      if (found != null) return found;
    }
    return null;
  }

  Package? _findPackageByProductId(
    Offering offering,
    String productId,
  ) =>
      offering.availablePackages.cast<Package?>().firstWhere(
            (p) =>
                p?.identifier == productId ||
                p?.storeProduct.identifier == productId,
            orElse: () => null,
          );

  void _notifyListeners({required bool isPremium}) {
    for (final listener in List.of(_listeners)) {
      listener(isPremium);
    }
  }

  void _debugDumpOfferings(Offerings offerings) {
    debugPrint(
      '[RevenueCat] current offering: ${offerings.current?.identifier}',
    );
    debugPrint(
      '[RevenueCat] all offering IDs: ${offerings.all.keys.toList()}',
    );
    for (final entry in offerings.all.entries) {
      for (final p in entry.value.availablePackages) {
        debugPrint(
          '[RevenueCat] offering "${entry.key}" package:'
          ' rcId=${p.identifier}'
          ' storeId=${p.storeProduct.identifier}'
          ' type=${p.packageType.name}'
          ' price=${p.storeProduct.price}'
          ' priceString=${p.storeProduct.priceString}',
        );
      }
    }
    final saleOffering = offerings.all[_saleOfferingId];
    debugPrint(
      '[RevenueCat] premium_sale offering found: ${saleOffering != null}',
    );
    if (saleOffering != null) {
      debugPrint(
        '[RevenueCat] premium_sale.monthly: ${saleOffering.monthly?.storeProduct.identifier} '
        'price=${saleOffering.monthly?.storeProduct.price}',
      );
      debugPrint(
        '[RevenueCat] premium_sale.lifetime: ${saleOffering.lifetime?.storeProduct.identifier} '
        'price=${saleOffering.lifetime?.storeProduct.price}',
      );
    }
  }
}
