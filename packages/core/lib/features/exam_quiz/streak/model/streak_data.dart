enum DayStatus { studied, frozen, missed, notYet }

class StreakData {
  const StreakData({
    this.currentStreak = 0,
    this.freezeCount = 1,
    this.lastStudiedDate,
    this.studiedDates = const [],
    this.frozenDates = const [],
    this.showBanner = false,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['currentStreak'] as int? ?? 0,
      freezeCount: json['freezeCount'] as int? ?? 1,
      lastStudiedDate: json['lastStudiedDate'] as String?,
      studiedDates: (json['studiedDates'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      frozenDates: (json['frozenDates'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  final int currentStreak;
  final int freezeCount;

  /// 最後に学習した日 (ISO date: `2026-04-27`)
  final String? lastStudiedDate;
  final List<String> studiedDates;
  final List<String> frozenDates;

  /// メモリ内のみ。永続化しない。
  final bool showBanner;

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'freezeCount': freezeCount,
        'lastStudiedDate': lastStudiedDate,
        'studiedDates': studiedDates,
        'frozenDates': frozenDates,
      };

  StreakData copyWith({
    int? currentStreak,
    int? freezeCount,
    String? lastStudiedDate,
    List<String>? studiedDates,
    List<String>? frozenDates,
    bool? showBanner,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      freezeCount: freezeCount ?? this.freezeCount,
      lastStudiedDate: lastStudiedDate ?? this.lastStudiedDate,
      studiedDates: studiedDates ?? this.studiedDates,
      frozenDates: frozenDates ?? this.frozenDates,
      showBanner: showBanner ?? this.showBanner,
    );
  }

  /// 直近7日分のステータスリスト（インデックス0が6日前、6が今日）。
  List<DayStatus> weeklyLog(DateTime today) {
    final todayStr = _dateStr(today);
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      final s = _dateStr(d);
      if (studiedDates.contains(s)) return DayStatus.studied;
      if (frozenDates.contains(s)) return DayStatus.frozen;
      if (s == todayStr) return DayStatus.notYet;
      return DayStatus.missed;
    });
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
