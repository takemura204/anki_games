import 'package:shared_preferences/shared_preferences.dart';

import '../model/notification_settings.dart';
import '../model/notification_time_slot.dart';

class NotificationRepository {
  static const _enabledKey = 'notification_enabled_v1';
  static const _hourKey = 'notification_hour_v2';
  static const _minuteKey = 'notification_minute_v2';
  static const _streakKey = 'notification_streak_reminder_v1';

  // v1 で使用していた旧キー（移行のみ）
  static const _legacySlotKey = 'notification_time_slot_v1';

  Future<NotificationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final streakEnabled = prefs.getBool(_streakKey) ?? true;

    var hour = prefs.getInt(_hourKey);
    var minute = prefs.getInt(_minuteKey);

    // 旧スロットキーからの移行
    if (hour == null && minute == null) {
      final slotName = prefs.getString(_legacySlotKey);
      if (slotName != null) {
        final slot = NotificationTimeSlot.values
            .where((s) => s.name == slotName)
            .firstOrNull;
        if (slot != null) {
          hour = slot.hour;
          minute = slot.minute;
          await prefs.setInt(_hourKey, hour);
          await prefs.setInt(_minuteKey, minute);
          await prefs.remove(_legacySlotKey);
        }
      }
    }

    return NotificationSettings(
      enabled: enabled,
      hour: hour,
      minute: minute,
      streakReminderEnabled: streakEnabled,
    );
  }

  Future<void> save(NotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    if (settings.hour != null) {
      await prefs.setInt(_hourKey, settings.hour!);
    } else {
      await prefs.remove(_hourKey);
    }
    if (settings.minute != null) {
      await prefs.setInt(_minuteKey, settings.minute!);
    } else {
      await prefs.remove(_minuteKey);
    }
    await prefs.setBool(_streakKey, settings.streakReminderEnabled);
  }
}
