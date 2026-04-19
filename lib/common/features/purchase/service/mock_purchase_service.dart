import 'package:anki_games/common/features/purchase/service/i_purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mockPremiumKey = 'mock_premium_enabled';

/// デバッグ用モック課金サービス。
///
/// [SharedPreferences] でプレミアム状態を永続化する。
/// kDebugMode 時に使用し、RevenueCat API キーなしで全機能を検証できる。
class MockPurchaseService implements IPurchaseService {
  final List<OnPremiumStatusChanged> _listeners = [];

  @override
  Future<void> configure() async {}

  @override
  Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_mockPremiumKey) ?? false;
  }

  @override
  Future<String?> getMonthlyPriceString() async => '¥480';

  @override
  Future<String?> getMonthlyProductTitle() async => 'Block. Premium';

  @override
  Future<void> purchaseMonthly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mockPremiumKey, true);
    _notifyListeners(isPremium: true);
  }

  @override
  Future<bool> restorePurchases() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_mockPremiumKey) ?? false;
    _notifyListeners(isPremium: value);
    return value;
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
  Future<void> logIn(String userId) async {}

  @override
  Future<void> logOut() async {}

  @override
  Future<void> toggleMockPremium() async {
    final current = await isPremium();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mockPremiumKey, !current);
    _notifyListeners(isPremium: !current);
  }

  void _notifyListeners({required bool isPremium}) {
    for (final listener in List.of(_listeners)) {
      listener(isPremium);
    }
  }
}
