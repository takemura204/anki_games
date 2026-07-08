import 'package:core/config/brand/brand_config.dart';
import 'package:core/config/lifecycle/app_lifecycle_provider.dart';
import 'package:core/config/theme/app_theme.dart' show buildAppTheme;
import 'package:core/features/exam_quiz/notification/repository/notification_repository.dart';
import 'package:core/features/exam_quiz/notification/service/notification_service.dart';
import 'package:core/features/exam_quiz/quiz/sync/quiz_sync_notifier.dart';
import 'package:core/features/exam_quiz/quiz/view/quiz_screen.dart';
import 'package:core/features/exam_quiz/streak/repository/local_streak_repository.dart';
import 'package:core/features/exam_quiz/streak/view/streak_banner.dart';
import 'package:core/features/settings/view_model/theme_mode_view_model.dart';
import 'package:core/utils/router/router_constants.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// LifecycleState 変化で通知スケジュールを更新する。
///
/// バックグラウンドから復帰した直後の一度だけ実行する。
void rescheduleStreakWarning() {
  NotificationRepository().load().then((settings) {
    if (!settings.enabled || !settings.streakReminderEnabled) return;
    LocalStreakRepository().load().then((streak) {
      final now = DateTime.now();
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      NotificationService.instance.updateStreakWarning(
        studiedToday: streak.lastStudiedDate == '${now.year}-$m-$d',
      );
    });
  });
}

/// 全試験アプリ共通のルートウィジェット。
///
/// `BrandConfig`/`ExamConfig` は呼び出し元の `ProviderScope.overrides` で注入済みとして使う。
class ExamQuizApp extends ConsumerWidget {
  const ExamQuizApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeViewModelProvider);
    final brandConfig = ref.watch(brandConfigProvider);

    ref
      ..read(quizSyncProvider)
      ..listen<AppLifecycleData>(appLifecycleProvider, (prev, next) {
        if (prev?.lastBgDuration == null && next.lastBgDuration != null) {
          rescheduleStreakWarning();
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
