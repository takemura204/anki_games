import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../model/notification_settings.dart';
import '../repository/notification_repository.dart';
import '../service/notification_service.dart';

part 'notification_view_model.g.dart';

@Riverpod(keepAlive: true)
class NotificationViewModel extends _$NotificationViewModel {
  final _repo = NotificationRepository();

  @override
  Future<NotificationSettings> build() async {
    final settings = await _repo.load();
    await NotificationService.instance.scheduleAll(settings);
    return settings;
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    await _repo.save(settings);
    await NotificationService.instance.scheduleAll(settings);
    state = AsyncData(settings);
  }

  Future<void> setTime(int hour, int minute) async {
    final current = state.asData?.value ?? const NotificationSettings();
    await saveSettings(current.copyWith(hour: hour, minute: minute));
  }

  Future<void> disable() async {
    final current = state.asData?.value ?? const NotificationSettings();
    await saveSettings(current.copyWith(enabled: false));
  }
}
