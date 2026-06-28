import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  OnboardingRepository({required String prefsPrefix})
      : _prefix = prefsPrefix;

  final String _prefix;

  String get _key => '${_prefix}_onboarding_v1';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
