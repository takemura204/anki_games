import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:app_it_pass/features/quiz/view/quiz_screen.dart';
import 'package:app_it_pass/features/settings/view_model/theme_mode_view_model.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/theme/app_theme.dart' show buildAppTheme;
import 'package:core/i18n/translations.g.dart';
import 'package:core/utils/router/router_constants.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocaleSettings.useDeviceLocale();

  runApp(
    TranslationProvider(
      child: const ProviderScope(child: ItPassApp()),
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
      theme: buildAppTheme(seedColor: AppColors.itPassSeed, dark: false)
          .copyWith(extensions: [ItPassColorScheme.light]),
      darkTheme: buildAppTheme(seedColor: AppColors.itPassSeed, dark: true)
          .copyWith(extensions: [ItPassColorScheme.dark]),
      home: const QuizScreen(),
    );
  }
}
