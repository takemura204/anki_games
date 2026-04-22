import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'it_pass_theme_mode';

final themeModeViewModelProvider =
    NotifierProvider<ThemeModeViewModel, ThemeMode>(ThemeModeViewModel.new);

class ThemeModeViewModel extends Notifier<ThemeMode> {
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
