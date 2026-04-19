import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view/modals/theme_selector_sheet.dart';
import 'package:anki_games/apps/block_puzzle/features/home/view/widgets/quiz_start_bottom_sheet.dart';
import 'package:anki_games/common/features/purchase/view/paywall_bottom_sheet.dart';
import 'package:anki_games/common/features/quiz/view_model/quiz_view_model.dart';
import 'package:anki_games/common/features/settings/view/settings_dialog.dart';
import 'package:anki_games/common/until/router/router_constants.dart';

/// モーダルボトムシートの表示を一元管理する Provider。
/// ViewModel から context 不要で呼び出せる。
final modalSheetRouterProvider =
    Provider<ModalSheetRouter>((ref) => ModalSheetRouter());

class ModalSheetRouter {
  BuildContext get _ctx => rootNavigatorKey.currentContext!;

  /// ホーム画面の設定シートを表示する。
  Future<void> showHomeSettings() async {
    await showModalBottomSheet<void>(
      context: _ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SettingsSheet(isGameScreen: false),
    );
  }

  /// ゲーム画面の設定シートを表示する。
  Future<void> showGameSettings() async {
    await showModalBottomSheet<void>(
      context: _ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SettingsSheet(isGameScreen: true),
    );
  }

  /// クイズ開始シートを表示し、ユーザーが Start を選択したか返す。
  Future<bool> showQuizStart(LevelFilter level) async {
    final result = await showModalBottomSheet<bool>(
      context: _ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuizStartSheet(level: level),
    );
    return result ?? false;
  }

  /// ペイウォールシートを表示する。
  Future<void> showPaywall() async {
    await showModalBottomSheet<void>(
      context: _ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const PaywallSheet(),
    );
  }

  /// テーマ選択シートを表示する。
  Future<void> showThemeSelector() async {
    await showModalBottomSheet<void>(
      context: _ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ThemeSelectorSheet(),
    );
  }
}
