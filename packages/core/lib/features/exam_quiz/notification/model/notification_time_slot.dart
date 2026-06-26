import 'package:flutter/material.dart';

enum NotificationTimeSlot {
  morning,
  commute,
  evening,
  bedtime;

  (int, int) get scheduledTime => switch (this) {
    NotificationTimeSlot.morning => (7, 0),
    NotificationTimeSlot.commute => (8, 0),
    NotificationTimeSlot.evening => (18, 30),
    NotificationTimeSlot.bedtime => (22, 0),
  };

  int get hour => scheduledTime.$1;
  int get minute => scheduledTime.$2;

  String get displayLabel => switch (this) {
    NotificationTimeSlot.morning => '起床時',
    NotificationTimeSlot.commute => '通勤・通学中',
    NotificationTimeSlot.evening => '退勤・帰宅後',
    NotificationTimeSlot.bedtime => '就寝前',
  };

  String get timeText => switch (this) {
    NotificationTimeSlot.morning => '07:00',
    NotificationTimeSlot.commute => '08:00',
    NotificationTimeSlot.evening => '18:30',
    NotificationTimeSlot.bedtime => '22:00',
  };

  String get notificationTitle => switch (this) {
    NotificationTimeSlot.morning => 'おはようございます！',
    NotificationTimeSlot.commute => '通勤時間を有効活用！',
    NotificationTimeSlot.evening => 'お疲れ様です！',
    NotificationTimeSlot.bedtime => '今日の学習はお済みですか？',
  };
  IconData get notificationIcon => switch (this) {
    NotificationTimeSlot.morning => Icons.wb_sunny_rounded,
    NotificationTimeSlot.commute => Icons.directions_transit_rounded,
    NotificationTimeSlot.evening => Icons.home_rounded,
    NotificationTimeSlot.bedtime => Icons.bedtime_rounded,
  };

  String get notificationBody => switch (this) {
    NotificationTimeSlot.morning => '今日のITパスポート学習を始めましょう。合格まであと一歩！',
    NotificationTimeSlot.commute => '隙間の5分でITパスポートに合格しよう。今日も1問ずつ積み上げよう',
    NotificationTimeSlot.evening => '帰りの時間を学習に。今日の問題をこなしてストリークを守ろう',
    NotificationTimeSlot.bedtime => '寝る前の5分で知識を定着。明日の自分への投資をしよう',
  };
}
