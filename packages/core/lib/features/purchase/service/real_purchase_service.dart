import 'dart:io';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../config/env/env.dart';
import 'i_purchase_service.dart';

const _entitlementId = 'premium';
const _offeringId = 'subscriptions';

/// RevenueCat を使った本番課金サービス。
///
/// `purchases_flutter` v9 の API を使用する。
/// [configure] はアプリ起動時に1度だけ呼ぶこと。
class RealPurchaseService implements IPurchaseService {
  final List<OnPremiumStatusChanged> _listeners = [];

  @override
  Future<void> configure() async {
    final apiKey =
        Platform.isIOS ? Env.revenueCatApiKeyIos : Env.revenueCatApiKeyAndroid;
    await Purchases.configure(PurchasesConfiguration(apiKey));
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
      return _findPackage(offerings)?.storeProduct.priceString;
    } on Exception catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getMonthlyProductTitle() async {
    try {
      final offerings = await Purchases.getOfferings();
      return _findPackage(offerings)?.storeProduct.title;
    } on Exception catch (_) {
      return null;
    }
  }

  @override
  Future<void> purchaseMonthly() async {
    final offerings = await Purchases.getOfferings();
    final package = _findPackage(offerings);
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
  Future<bool> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    return _isPremiumFromInfo(info);
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
  Future<void> logIn(String userId) async {
    await Purchases.logIn(userId);
  }

  @override
  Future<void> logOut() async {
    await Purchases.logOut();
  }

  @override
  Future<void> toggleMockPremium() async {}

  bool _isPremiumFromInfo(CustomerInfo info) =>
      info.entitlements.all[_entitlementId]?.isActive ?? false;

  /// "subscriptions" offering からパッケージを取得する。
  ///
  /// まず [Offering.monthly]（packageType = monthly）で検索し、
  /// 見つからない場合は [Env.premium1m] の product identifier で線形探索する。
  Package? _findPackage(Offerings offerings) {
    final offering = offerings.all[_offeringId];
    if (offering == null) {
      return null;
    }
    return offering.monthly ??
        offering.availablePackages.cast<Package?>().firstWhere(
              (p) => p?.storeProduct.identifier == Env.premium1m,
              orElse: () => null,
            );
  }

  void _notifyListeners({required bool isPremium}) {
    for (final listener in List.of(_listeners)) {
      listener(isPremium);
    }
  }
}
