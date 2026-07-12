import 'dart:io';

class RevenueCatConfig {
  const RevenueCatConfig({
    required this.apiKeyIos,
    required this.apiKeyAndroid,
    required this.premium1mProductId,
    required this.premiumLifetimeProductId,
    this.premium1mSaleProductId = '',
    this.premiumLifetimeSaleProductId = '',
  });

  final String apiKeyIos;
  final String apiKeyAndroid;
  final String premium1mProductId;
  final String premiumLifetimeProductId;
  final String premium1mSaleProductId;
  final String premiumLifetimeSaleProductId;

  String get apiKey => Platform.isIOS ? apiKeyIos : apiKeyAndroid;
}
