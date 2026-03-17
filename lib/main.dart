import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/home/view/home_screen.dart';
import 'package:mono_games/i18n/translations.g.dart';
import 'package:mono_games/until/service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await LocaleSettings.useDeviceLocale();
  // SharedPreferences を事前ロードしてキャッシュを確立する。
  // これにより、プロバイダの非同期初期化（_loadSavedGame 等）が
  // ホーム画面の startQuestLevel 呼び出しより後に解決される競合を防ぐ。
  await SharedPreferences.getInstance();
  // 頻繁に再生する効果音をキャッシュへ事前ロードし、初回再生の遅延を排除する。
  await AudioService.instance.preload([
    'sounds/block_puzzle/block_select.mp3',
  ]);
  runApp(TranslationProvider(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: _MaterialApp(),
    );
  }
}

class _MaterialApp extends HookConsumerWidget {
  const _MaterialApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: t.appTitle,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: FlexThemeData.light(scheme: FlexScheme.blackWhite),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.blackWhite),
      home: const HomeScreen(),
    );
  }
}
