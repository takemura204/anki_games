import 'package:core/config/brand/brand_config.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_view_model.g.dart';

@Riverpod(keepAlive: true)
class ThemeModeViewModel extends _$ThemeModeViewModel {
  late final String _key;

  @override
  ThemeMode build() {
    final prefix = ref.watch(brandConfigProvider).analyticsBrandKey;
    _key = '${prefix}_theme_mode';
    _load();
    return ThemeMode.dark;
  }

  void _load() {
    SharedPreferences.getInstance().then((prefs) {
      final raw = prefs.getString(_key);
      state = _parse(raw);
    });
  }

  void setMode(ThemeMode mode) {
    state = mode;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_key, _serialize(mode)));
  }

  static ThemeMode _parse(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.dark,
      };

  static String _serialize(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };
}
