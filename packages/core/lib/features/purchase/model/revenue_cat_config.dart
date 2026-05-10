import 'dart:io';

class RevenueCatConfig {
  const RevenueCatConfig({
    required this.apiKeyIos,
    required this.apiKeyAndroid,
    required this.premium1mProductId,
    required this.premiumLifetimeProductId,
  });

  final String apiKeyIos;
  final String apiKeyAndroid;
  final String premium1mProductId;
  final String premiumLifetimeProductId;

  String get apiKey => Platform.isIOS ? apiKeyIos : apiKeyAndroid;
}
