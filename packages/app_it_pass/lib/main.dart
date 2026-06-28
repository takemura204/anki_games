import 'package:app_it_pass/config/brand/it_pass_brand_config.dart';
import 'package:app_it_pass/config/env/env.dart';
import 'package:app_it_pass/config/exam/it_pass_exam_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/config/ads/ad_config.dart';
import 'package:core/config/brand/brand_config.dart';
import 'package:core/config/lifecycle/app_lifecycle_provider.dart';
import 'package:core/config/theme/app_theme.dart' show buildAppTheme;
import 'package:core/features/exam_quiz/config/exam_config.dart';
import 'package:core/features/exam_quiz/notification/repository/notification_repository.dart';
import 'package:core/features/exam_quiz/notification/service/notification_service.dart';
import 'package:core/features/exam_quiz/quiz/sync/quiz_sync_notifier.dart';
import 'package:core/features/exam_quiz/quiz/view/quiz_screen.dart';
import 'package:core/features/exam_quiz/streak/repository/local_streak_repository.dart';
import 'package:core/features/exam_quiz/streak/view/streak_banner.dart';
import 'package:core/features/purchase/model/revenue_cat_config.dart';
import 'package:core/features/purchase/service/real_purchase_service.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/features/settings/view_model/theme_mode_view_model.dart';
import 'package:core/firebase_options.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:core/utils/router/router_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _useEmulator = bool.fromEnvironment('USE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize(channelId: 'it_pass_reminder');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await MobileAds.instance.initialize();
  if (kDebugMode) {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: const []),
    );
  }

  if (_useEmulator) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  }

  await LocaleSettings.useDeviceLocale();

  // 起動時に通知をスケジュール（冪等: 既存スケジュールを上書き）
  final notificationSettings = await NotificationRepository().load();
  await NotificationService.instance.scheduleAll(notificationSettings);


  runApp(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          brandConfigProvider.overrideWithValue(
            const ItPassBrandConfig(),
          ),
          examConfigProvider.overrideWithValue(
            const ItPassExamConfig(),
          ),
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

void _rescheduleStreakWarning() {
  NotificationRepository().load().then((settings) {
    if (!settings.enabled || !settings.streakReminderEnabled) return;
    LocalStreakRepository().load().then((streak) {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      NotificationService.instance.updateStreakWarning(
        studiedToday: streak.lastStudiedDate == today,
      );
    });
  });
}

class ItPassApp extends ConsumerWidget {
  const ItPassApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeViewModelProvider);
    final brandConfig = ref.watch(brandConfigProvider);

    // クイズデータのバックグラウンド同期を起動する（ウォッチしないので UI をブロックしない）
    ref
      ..read(quizSyncProvider)
      ..listen<AppLifecycleData>(appLifecycleProvider, (prev, next) {
        if (prev?.lastBgDuration == null && next.lastBgDuration != null) {
          _rescheduleStreakWarning();
        }
      });

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: brandConfig.appName,
      themeMode: themeMode,
      theme: buildAppTheme(
        seedColor: brandConfig.seedColor,
      ).copyWith(extensions: brandConfig.lightThemeExtensions),
      darkTheme: buildAppTheme(
        seedColor: brandConfig.seedColor,
        dark: true,
      ).copyWith(extensions: brandConfig.darkThemeExtensions),
      builder: (context, child) => StreakBannerHost(child: child!),
      home: const QuizScreen(),
    );
  }
}
