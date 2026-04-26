import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_view_model.g.dart';

const _kThemeModeKey = 'it_pass_theme_mode';

@Riverpod(keepAlive: true)
class ThemeModeViewModel extends _$ThemeModeViewModel {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  void _load() {
    SharedPreferences.getInstance().then((prefs) {
      final raw = prefs.getString(_kThemeModeKey);
      state = _parse(raw);
    });
  }

  void setMode(ThemeMode mode) {
    state = mode;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_kThemeModeKey, _serialize(mode)));
  }

  static ThemeMode _parse(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _serialize(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      };
}
