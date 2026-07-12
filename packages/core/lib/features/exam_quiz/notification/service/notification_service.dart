import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../model/notification_settings.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  // 曜日別リマインダー: ID 10(月)〜16(日)
  static const _weeklyBaseId = 10;
  static const _streakWarningId = 2;
  static const _testNotificationId = 99;
  static const _channelName = '学習リマインダー';

  String _channelId = 'exam_reminder';

  // 曜日別メッセージ (index 0=月, 1=火, ... 6=日)
  static const _weekdayTitles = [
    '新しい週の始まり',
    '昨日より1歩前へ',
    '週の折り返し',
    'あと一踏ん張り',
    '今週の締めくくり',
    '週末の学習時間',
    '明日に備えて',
  ];

  static const _weekdayBodies = [
    '今週も1問ずつ積み上げよう。継続が合格への近道！',
    '昨日のあなたより少しだけ賢くなろう',
    'ここまで来たら後半も続けよう',
    '木曜日こそ習慣の力を感じる日。今日も1問こなそう',
    '週末前に今週の学習を確認しよう',
    '時間のある今日こそ、まとめて問題を解くチャンス',
    '今週の振り返りと来週の準備をしよう',
  ];

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize({String channelId = 'exam_reminder'}) async {
    _channelId = channelId;
    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  /// 通知権限を要求する。
  /// iOS: flutter_local_notifications の requestPermissions で OS ダイアログを確実に表示。
  /// Android: permission_handler で OS ダイアログを表示。
  /// [showSettingsDialogOnDenied] が true のとき、拒否済みなら設定アプリへの誘導ダイアログを表示。
  /// オンボーディングなど「拒否しても問題ない」文脈では false を渡す。
  Future<bool> requestPermission(
    BuildContext context, {
    bool showSettingsDialogOnDenied = true,
  }) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    bool granted;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS は UNUserNotificationCenter.requestAuthorization を直接呼ぶ実装を使用。
      // permission_handler は notDetermined を denied と同様に扱うため OS ダイアログが出ない場合がある。
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      granted = await iosImpl?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    } else {
      final result = await Permission.notification.request();
      granted = result.isGranted;
    }

    if (!granted && showSettingsDialogOnDenied && context.mounted) {
      await _showOpenSettingsDialog(context);
    }
    return granted;
  }

  Future<bool> isPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<void> scheduleAll(NotificationSettings settings) async {
    if (!settings.enabled || settings.hour == null || settings.minute == null) {
      await cancelAll();
      return;
    }
    await _scheduleWeeklyReminders(settings.hour!, settings.minute!);
    if (settings.streakReminderEnabled) {
      await _scheduleStreakWarning(studiedToday: false);
    } else {
      await _plugin.cancel(_streakWarningId);
    }
  }

  /// アプリ復帰時に今日の学習状態に応じてストリーク警告を更新する。
  Future<void> updateStreakWarning({required bool studiedToday}) async {
    if (studiedToday) {
      await _plugin.cancel(_streakWarningId);
    } else {
      await _scheduleStreakWarning(studiedToday: false);
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> showTestNotification() => _plugin.show(
        _testNotificationId,
        'テスト通知',
        '通知は正常に届いています。',
        _buildDetails(),
        payload: 'quiz_start',
      );

  Future<void> _scheduleWeeklyReminders(int hour, int minute) async {
    // 曜日ごとに個別スケジュール (flutter の weekday: 1=月 〜 7=日)
    for (var weekday = 1; weekday <= 7; weekday++) {
      final msgIndex = weekday - 1;
      await _plugin.zonedSchedule(
        _weeklyBaseId + msgIndex,
        _weekdayTitles[msgIndex],
        _weekdayBodies[msgIndex],
        _nextWeekdayTime(weekday, hour, minute),
        _buildDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'quiz_start',
      );
    }
  }

  Future<void> _scheduleStreakWarning({required bool studiedToday}) async {
    if (studiedToday) {
      await _plugin.cancel(_streakWarningId);
      return;
    }
    await _plugin.zonedSchedule(
      _streakWarningId,
      '⚠ ストリークが途切れそうです',
      '今日まだ学習していません。1問だけでもこなしてストリークを守ろう！',
      _nextTime(22, 30),
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'quiz_start',
    );
  }

  tz.TZDateTime _nextWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var dt = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    // 指定曜日になるまで1日ずつ進める
    while (dt.weekday != weekday || dt.isBefore(now.add(const Duration(minutes: 1)))) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var dt =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (dt.isBefore(now.add(const Duration(minutes: 1)))) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  NotificationDetails _buildDetails() => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: '毎日の学習リマインダーと継続サポート通知',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  Future<void> _showOpenSettingsDialog(BuildContext context) async {
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('通知の許可が必要です'),
        content: const Text(
          '設定アプリから通知を「許可」に変更してください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('後で'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
    if (shouldOpen == true) await openAppSettings();
  }
}
