import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../model/revenue_cat_config.dart';
import 'i_purchase_service.dart';

const _entitlementId = 'premium';
const _offeringId = 'premium';

/// RevenueCat を使った本番課金サービス。
///
/// [configure] はアプリ起動時に1度だけ呼ぶこと。
class RealPurchaseService implements IPurchaseService {
  RealPurchaseService(this._config);

  final RevenueCatConfig _config;
  final List<OnPremiumStatusChanged> _listeners = [];

  @override
  Future<void> configure() async {
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
  Future<String?> getMonthlyPriceString() async {
    try {
      final offerings = await Purchases.getOfferings();
      _debugDumpOfferings(offerings);
      final price = _findMonthlyPackage(offerings)?.storeProduct.priceString;
      if (price == null) {
        debugPrint(
          '[RevenueCat] getMonthlyPriceString: package not found'
          ' in offering "$_offeringId"',
        );
      }
      return price;
    } on Exception catch (e) {
      debugPrint('[RevenueCat] getMonthlyPriceString error: $e');
      return null;
    }
  }

  @override
  Future<String?> getMonthlyProductTitle() async {
    try {
      final offerings = await Purchases.getOfferings();
      return _findMonthlyPackage(offerings)?.storeProduct.title;
    } on Exception catch (e) {
      debugPrint('[RevenueCat] getMonthlyProductTitle error: $e');
      return null;
    }
  }

  @override
  Future<String?> getLifetimePriceString() async {
    try {
      final offerings = await Purchases.getOfferings();
      final price = _findLifetimePackage(offerings)?.storeProduct.priceString;
      if (price == null) {
        debugPrint(
          '[RevenueCat] getLifetimePriceString: package not found'
          ' in offering "$_offeringId"',
        );
      }
      return price;
    } on Exception catch (e) {
      debugPrint('[RevenueCat] getLifetimePriceString error: $e');
      return null;
    }
  }

  @override
  Future<void> purchaseMonthly() async {
    final offerings = await Purchases.getOfferings();
    final package = _findMonthlyPackage(offerings);
    if (package == null) {
      throw Exception(
        'Monthly package not available in offering "$_offeringId"',
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
  Future<void> purchaseLifetime() async {
    final offerings = await Purchases.getOfferings();
    final package = _findLifetimePackage(offerings);
    if (package == null) {
      throw Exception(
        'Lifetime package not available in offering "$_offeringId"',
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

  Package? _findMonthlyPackage(Offerings offerings) {
    final offering = offerings.all[_offeringId];
    if (offering == null) {
      return null;
    }
    return offering.monthly ??
        offering.availablePackages.cast<Package?>().firstWhere(
              (p) =>
                  p?.identifier == _config.premium1mProductId ||
                  p?.storeProduct.identifier == _config.premium1mProductId,
              orElse: () => null,
            );
  }

  Package? _findLifetimePackage(Offerings offerings) {
    final offering = offerings.all[_offeringId];
    if (offering == null) {
      return null;
    }
    return offering.lifetime ??
        offering.availablePackages.cast<Package?>().firstWhere(
              (p) =>
                  p?.identifier == _config.premiumLifetimeProductId ||
                  p?.storeProduct.identifier ==
                      _config.premiumLifetimeProductId,
              orElse: () => null,
            );
  }

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
          ' type=${p.packageType.name}',
        );
      }
    }
  }
}
