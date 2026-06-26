import 'package:shared_preferences/shared_preferences.dart';

class MotivationLastShownRepository {
  static const _key = 'motivation_last_shown_at';
  static const _gapThreshold = Duration(hours: 6);

  /// モチベーション画面を表示すべきか判定する。
  /// 今日初めての起動、または前回表示から6時間以上経過した場合に true を返す。
  Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_key);
    if (millis == null) return true;

    final last = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();

    final isNewDay =
        last.year != now.year ||
        last.month != now.month ||
        last.day != now.day;
    if (isNewDay) return true;

    return now.difference(last) >= _gapThreshold;
  }

  Future<void> recordShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, DateTime.now().millisecondsSinceEpoch);
  }
}
