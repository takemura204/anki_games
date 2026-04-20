import 'package:anki_games/apps/block_puzzle/features/home/view/home_screen.dart';
import 'package:anki_games/common/features/quiz/view/word_range_selector_screen.dart';
import 'package:anki_games/common/utils/router/play_session_screen.dart';
import 'package:anki_games/common/utils/router/router_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

export 'package:anki_games/common/utils/router/router_constants.dart';

final screenRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: ScreenRoutes.home,
    routes: [
      GoRoute(
        path: ScreenRoutes.home,
        pageBuilder: (context, state) => const MaterialPage(
          child: HomeScreen(),
        ),
      ),
      GoRoute(
        path: ScreenRoutes.game,
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: PlaySessionScreen(),
          transitionsBuilder: _slideFromRight,
        ),
      ),
      GoRoute(
        path: ScreenRoutes.wordRange,
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: WordRangeSelectorScreen(),
          transitionsBuilder: _slideFromRight,
        ),
      ),
    ],
  );
});

Widget _slideFromRight(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) =>
    SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
      child: child,
    );
