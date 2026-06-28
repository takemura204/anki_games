import 'package:flutter/material.dart';

/// GoRouter に渡すグローバル NavigatorKey。
/// ViewModel からコンテキスト不要で画面遷移・モーダル表示をするために使用する。
final rootNavigatorKey = GlobalKey<NavigatorState>();
