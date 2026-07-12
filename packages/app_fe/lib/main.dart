import 'package:core/app/exam_quiz_app.dart';
import 'package:core/config/ads/ad_config.dart';
import 'package:core/config/brand/brand_config.dart';
import 'package:core/features/exam_quiz/config/exam_config.dart';
import 'package:core/features/exam_quiz/notification/repository/notification_repository.dart';
import 'package:core/features/exam_quiz/notification/service/notification_service.dart';
import 'package:core/features/purchase/service/real_purchase_service.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/firebase_options.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'config/app_fe_brand_config.dart';
import 'config/app_fe_exam_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const brand = AppFeBrandConfig();

  await NotificationService.instance.initialize(
    channelId: brand.notificationChannelId,
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await MobileAds.instance.initialize();
  await LocaleSettings.useDeviceLocale();

  final notificationSettings = await NotificationRepository().load();
  await NotificationService.instance.scheduleAll(notificationSettings);

  runApp(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          brandConfigProvider.overrideWithValue(brand),
          examConfigProvider.overrideWithValue(const AppFeExamConfig()),
          adConfigProvider.overrideWithValue(brand.adConfig),
          purchaseServiceProvider.overrideWithValue(
            RealPurchaseService(brand.revenueCatConfig),
          ),
        ],
        child: const ExamQuizApp(),
      ),
    ),
  );
}
