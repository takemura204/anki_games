import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_settings.freezed.dart';

@freezed
abstract class NotificationSettings with _$NotificationSettings {
  const factory NotificationSettings({
    @Default(false) bool enabled,
    int? hour,
    int? minute,
    @Default(true) bool streakReminderEnabled,
  }) = _NotificationSettings;
}
