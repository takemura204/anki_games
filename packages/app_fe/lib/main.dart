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
import 'package:core/features/purchase/service/real_purchase_service.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/features/settings/view_model/theme_mode_view_model.dart';
import 'package:core/firebase_options.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:core/utils/router/router_constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'config/app_fe_brand_config.dart';
import 'config/app_fe_exam_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize(channelId: 'fe_reminder');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await MobileAds.instance.initialize();
  await LocaleSettings.useDeviceLocale();

  final notificationSettings = await NotificationRepository().load();
  await NotificationService.instance.scheduleAll(notificationSettings);

  runApp(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          brandConfigProvider.overrideWithValue(const AppFeBrandConfig()),
          examConfigProvider.overrideWithValue(const AppFeExamConfig()),
          adConfigProvider.overrideWithValue(const AppFeBrandConfig().adConfig),
          purchaseServiceProvider.overrideWithValue(
            RealPurchaseService(const AppFeBrandConfig().revenueCatConfig),
          ),
        ],
        child: const AppFeApp(),
      ),
    ),
  );
}

void _rescheduleStreakWarning() {
  NotificationRepository().load().then((settings) {
    if (!settings.enabled || !settings.streakReminderEnabled) {
      return;
    }
    LocalStreakRepository().load().then((streak) {
      final now = DateTime.now();
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      final today = '${now.year}-$m-$d';
      NotificationService.instance.updateStreakWarning(
        studiedToday: streak.lastStudiedDate == today,
      );
    });
  });
}

class AppFeApp extends ConsumerWidget {
  const AppFeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeViewModelProvider);
    final brandConfig = ref.watch(brandConfigProvider);

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
      theme: buildAppTheme(seedColor: brandConfig.seedColor)
          .copyWith(extensions: brandConfig.lightThemeExtensions),
      darkTheme: buildAppTheme(
        seedColor: brandConfig.seedColor,
        dark: true,
      ).copyWith(extensions: brandConfig.darkThemeExtensions),
      builder: (context, child) => StreakBannerHost(child: child!),
      home: const QuizScreen(),
    );
  }
}
