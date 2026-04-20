import 'package:anki_games/apps/block_puzzle/features/block_puzzle/model/game_theme.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view_model/theme_view_model.dart';
import 'package:anki_games/common/config/styles/app_text_style.dart';
import 'package:anki_games/common/features/purchase/service/i_purchase_service.dart';
import 'package:anki_games/common/features/purchase/service/mock_purchase_service.dart';
import 'package:anki_games/common/features/purchase/service/real_purchase_service.dart';
import 'package:anki_games/common/features/purchase/view_model/premium_view_model.dart';
import 'package:anki_games/common/i18n/translations.g.dart';
import 'package:anki_games/common/utils/router/screen_router.dart';
import 'package:anki_games/common/utils/service/audio_service.dart';
import 'package:anki_games/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Block Puzzle のエントリ。ストア本番向けは [initializeFirebase] を true にする。
Future<void> runBlockPuzzleApp({required bool initializeFirebase}) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (initializeFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await MobileAds.instance.initialize();
  await LocaleSettings.useDeviceLocale();
  final prefs = await SharedPreferences.getInstance();
  final wasOnPuzzle = prefs.getBool('was_on_puzzle_screen') ?? false;
  final initialLevelKey =
      wasOnPuzzle ? prefs.getString('last_level_key') : null;
  await AudioService.instance.preload([
    'sounds/block_puzzle/block_select.mp3',
  ]);

  final purchaseService = kDebugMode
      ? MockPurchaseService() as IPurchaseService
      : RealPurchaseService();
  await purchaseService.configure();

  runApp(
    TranslationProvider(
      child: MyApp(
        purchaseService: purchaseService,
        initialLevelKey: initialLevelKey,
      ),
    ),
  );
}

/// Block Puzzle のルートウィジェット。
class MyApp extends StatelessWidget {
  const MyApp({
    required this.purchaseService,
    this.initialLevelKey,
    super.key,
  });

  final IPurchaseService purchaseService;
  final String? initialLevelKey;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        purchaseServiceProvider.overrideWithValue(purchaseService),
        if (initialLevelKey != null)
          initialLevelKeyProvider.overrideWithValue(initialLevelKey),
      ],
      child: const _MaterialApp(),
    );
  }
}

class _MaterialApp extends HookConsumerWidget {
  const _MaterialApp();

  ThemeData _buildTheme(GameThemeColors colors, {bool dark = false}) {
    final base = dark
        ? FlexThemeData.dark(
            scheme: FlexScheme.blackWhite,
            textTheme: AppTextStyle.textTheme,
          )
        : FlexThemeData.light(
            scheme: FlexScheme.blackWhite,
            textTheme: AppTextStyle.textTheme,
          );
    return base.copyWith(
      scaffoldBackgroundColor: colors.surface,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        surface: colors.surface,
        onSurface: colors.onSurface,
        primary: colors.accent,
        onPrimary: colors.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameTheme = ref.watch(themeViewModelProvider);
    final router = ref.watch(screenRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: t.appTitle,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: _buildTheme(gameTheme.colors),
      darkTheme:
          _buildTheme(gameTheme.colorsDark ?? gameTheme.colors, dark: true),
      routerConfig: router,
    );
  }
}
