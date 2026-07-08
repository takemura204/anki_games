import 'package:app_it_pass/config/brand/it_pass_brand_config.dart';
import 'package:app_it_pass/config/exam/it_pass_exam_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _useEmulator = bool.fromEnvironment('USE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const brand = ItPassBrandConfig();

  await NotificationService.instance.initialize(
    channelId: brand.notificationChannelId,
  );
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

  final notificationSettings = await NotificationRepository().load();
  await NotificationService.instance.scheduleAll(notificationSettings);

  runApp(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          brandConfigProvider.overrideWithValue(brand),
          examConfigProvider.overrideWithValue(const ItPassExamConfig()),
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
