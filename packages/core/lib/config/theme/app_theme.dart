import 'package:core/config/styles/app_text_style.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// 全アプリ共通の [ThemeData] ビルダー。
///
/// [AppTextStyle.textTheme] を基盤とし、[FlexThemeData] でベーステーマを構築する。
/// 各アプリは [seedColor] を渡してブランドカラーを適用し、必要に応じて
/// [surfaceColor] / [onSurfaceColor] でゲームテーマ等の上書きを行う。
///
/// 使用例:
/// ```dart
/// theme: buildAppTheme(seedColor: AppColors.itPassSeed, dark: true),
/// ```
ThemeData buildAppTheme({
  required Color seedColor,
  bool dark = false,
  Color? surfaceColor,
  Color? onSurfaceColor,
  Color? primaryColor,
}) {
  final base = dark
      ? FlexThemeData.dark(
          scheme: FlexScheme.blackWhite,
          textTheme: AppTextStyle.textTheme,
        )
      : FlexThemeData.light(
          scheme: FlexScheme.blackWhite,
          textTheme: AppTextStyle.textTheme,
        );

  var colorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor ?? seedColor,
    brightness: dark ? Brightness.dark : Brightness.light,
  );

  if (surfaceColor != null || onSurfaceColor != null || primaryColor != null) {
    colorScheme = colorScheme.copyWith(
      surface: surfaceColor,
      onSurface: onSurfaceColor,
      primary: primaryColor ?? seedColor,
      onPrimary: surfaceColor,
    );
  }

  return base.copyWith(
    scaffoldBackgroundColor: surfaceColor,
    colorScheme: colorScheme,
  );
}
