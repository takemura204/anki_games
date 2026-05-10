import 'package:app_it_pass/config/env/env.dart';
import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:app_it_pass/features/quiz/view/quiz_screen.dart';
import 'package:app_it_pass/features/settings/view_model/theme_mode_view_model.dart';
import 'package:app_it_pass/features/streak/view/streak_banner.dart';
import 'package:core/config/ads/ad_config.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/theme/app_theme.dart' show buildAppTheme;
import 'package:core/features/purchase/model/revenue_cat_config.dart';
import 'package:core/features/purchase/service/real_purchase_service.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/firebase_options.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:core/utils/router/router_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LocaleSettings.useDeviceLocale();

  runApp(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          adConfigProvider.overrideWithValue(
            const AdConfig(
              bannerAndroidDebug: ItPassEnv.bannerAndroidDebug,
              bannerAndroidRelease: ItPassEnv.bannerAndroidRelease,
              bannerIosDebug: ItPassEnv.bannerIosDebug,
              bannerIosRelease: ItPassEnv.bannerIosRelease,
              nativeAndroidDebug: ItPassEnv.nativeAndroidDebug,
              nativeAndroidRelease: ItPassEnv.nativeAndroidRelease,
              nativeIosDebug: ItPassEnv.nativeIosDebug,
              nativeIosRelease: ItPassEnv.nativeIosRelease,
              rewardedAndroidDebug: ItPassEnv.rewardedAndroidDebug,
              rewardedAndroidRelease: ItPassEnv.rewardedAndroidRelease,
              rewardedIosDebug: ItPassEnv.rewardedIosDebug,
              rewardedIosRelease: ItPassEnv.rewardedIosRelease,
              interstitialAndroidDebug: ItPassEnv.interstitialAndroidDebug,
              interstitialAndroidRelease: ItPassEnv.interstitialAndroidRelease,
              interstitialIosDebug: ItPassEnv.interstitialIosDebug,
              interstitialIosRelease: ItPassEnv.interstitialIosRelease,
            ),
          ),
          purchaseServiceProvider.overrideWithValue(
            RealPurchaseService(
              const RevenueCatConfig(
                apiKeyIos: ItPassEnv.revenueCatApiKeyIos,
                apiKeyAndroid: ItPassEnv.revenueCatApiKeyAndroid,
                premium1mProductId: ItPassEnv.premium1m,
                premiumLifetimeProductId: ItPassEnv.premiumLifetime,
              ),
            ),
          ),
        ],
        child: const ItPassApp(),
      ),
    ),
  );
}

class ItPassApp extends ConsumerWidget {
  const ItPassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeViewModelProvider);
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'IT Pass',
      themeMode: themeMode,
      theme: buildAppTheme(
        seedColor: AppColors.itPassSeed,
        dark: false,
      ).copyWith(extensions: [ItPassColorScheme.light]),
      darkTheme: buildAppTheme(
        seedColor: AppColors.itPassSeed,
        dark: true,
      ).copyWith(extensions: [ItPassColorScheme.dark]),
      builder: (context, child) => StreakBannerHost(child: child!),
      home: const QuizScreen(),
    );
  }
}
