import 'package:app_block_puzzle/router/screen_router.dart';
import 'package:core/config/theme/app_theme.dart' show buildAppTheme;
import 'package:core/features/purchase/service/i_purchase_service.dart';
import 'package:core/features/purchase/service/mock_purchase_service.dart';
import 'package:core/features/purchase/service/real_purchase_service.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/firebase_options.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:core/utils/service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/block_puzzle/model/game_theme.dart';
import '../features/block_puzzle/view_model/theme_view_model.dart';

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
    'assets/sounds/block_puzzle/block_select.mp3',
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
    return buildAppTheme(
      seedColor: colors.accent,
      dark: dark,
      surfaceColor: colors.surface,
      onSurfaceColor: colors.onSurface,
      primaryColor: colors.accent,
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
