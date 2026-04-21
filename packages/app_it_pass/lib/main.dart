import 'package:app_it_pass/features/quiz/view/quiz_screen.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/theme/app_theme.dart' show buildAppTheme;
import 'package:core/i18n/translations.g.dart';
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

class ItPassApp extends StatelessWidget {
  const ItPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IT Pass',
      theme: buildAppTheme(seedColor: AppColors.itPassSeed, dark: true),
      home: const QuizScreen(),
    );
  }
}
