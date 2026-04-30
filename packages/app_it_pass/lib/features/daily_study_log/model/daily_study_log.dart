class DailyStudyLog {
  const DailyStudyLog({
    required this.date,
    this.studySeconds = 0,
    this.newReviewCount = 0,
  });

  factory DailyStudyLog.fromJson(Map<String, dynamic> json) => DailyStudyLog(
        date: json['date'] as String,
        studySeconds: json['studySeconds'] as int? ?? 0,
        newReviewCount: json['newReviewCount'] as int? ?? 0,
      );

  /// "yyyy-MM-dd" 形式の日付キー
  final String date;

  /// 今日のセッション学習時間（秒）
  final int studySeconds;

  /// 今日初めて不正解になった問題数
  final int newReviewCount;

  DailyStudyLog copyWith({
    int? studySeconds,
    int? newReviewCount,
  }) =>
      DailyStudyLog(
        date: date,
        studySeconds: studySeconds ?? this.studySeconds,
        newReviewCount: newReviewCount ?? this.newReviewCount,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'studySeconds': studySeconds,
        'newReviewCount': newReviewCount,
      };
}
