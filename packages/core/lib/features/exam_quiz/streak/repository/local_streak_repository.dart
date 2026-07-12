import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/streak_data.dart';
import 'streak_repository.dart';

class LocalStreakRepository implements StreakRepository {
  static const _key = 'streak_v1';

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<StreakData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const StreakData();
    return StreakData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveForSync(StreakData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }

  @override
  Future<StreakData> recordStudy(DateTime today) async {
    final current = await load();
    final todayStr = _dateStr(today);

    if (current.lastStudiedDate == todayStr) {
      return current;
    }

    final yesterdayStr = _dateStr(today.subtract(const Duration(days: 1)));
    final twoDaysAgoStr = _dateStr(today.subtract(const Duration(days: 2)));

    int newStreak;
    var newFreezeCount = current.freezeCount;
    final newFrozenDates = [...current.frozenDates];

    if (current.lastStudiedDate == null) {
      newStreak = 1;
    } else if (current.lastStudiedDate == yesterdayStr) {
      newStreak = current.currentStreak + 1;
    } else if (current.lastStudiedDate == twoDaysAgoStr &&
        current.freezeCount > 0) {
      newStreak = current.currentStreak + 1;
      newFreezeCount = current.freezeCount - 1;
      newFrozenDates.add(yesterdayStr);
    } else {
      newStreak = 1;
    }

    final updated = current.copyWith(
      currentStreak: newStreak,
      freezeCount: newFreezeCount,
      lastStudiedDate: todayStr,
      studiedDates: [...current.studiedDates, todayStr],
      frozenDates: newFrozenDates,
      showBanner: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(updated.toJson()));
    return updated;
  }
}
