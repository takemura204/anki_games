import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// GoRouter に渡すグローバル NavigatorKey。
/// ViewModelからコンテキスト不要で画面遷移・モーダル表示をするために使用する。
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// 起動時に復元するレベルキー（null の場合は通常起動）。
/// main() の ProviderScope.overrides で注入される。
final initialLevelKeyProvider = Provider<String?>((_) => null);

/// ルートパスを一元管理。
abstract class ScreenRoutes {
  static const home = '/';
  static const game = '/game';
  static const wordRange = '/word-range';
}
