class DailyStudyLog {
  const DailyStudyLog({
    required this.date,
    this.studySeconds = 0,
    this.newReviewCount = 0,
    this.answeredCount = 0,
    this.correctCount = 0,
  });

  factory DailyStudyLog.fromJson(Map<String, dynamic> json) => DailyStudyLog(
        date: json['date'] as String,
        studySeconds: json['studySeconds'] as int? ?? 0,
        newReviewCount: json['newReviewCount'] as int? ?? 0,
        answeredCount: json['answeredCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
      );

  /// "yyyy-MM-dd" 形式の日付キー
  final String date;

  /// 今日のセッション学習時間（秒）
  final int studySeconds;

  /// 今日初めて不正解になった問題数
  final int newReviewCount;

  /// 今日の解答数
  final int answeredCount;

  /// 今日の正解数
  final int correctCount;

  DailyStudyLog copyWith({
    int? studySeconds,
    int? newReviewCount,
    int? answeredCount,
    int? correctCount,
  }) =>
      DailyStudyLog(
        date: date,
        studySeconds: studySeconds ?? this.studySeconds,
        newReviewCount: newReviewCount ?? this.newReviewCount,
        answeredCount: answeredCount ?? this.answeredCount,
        correctCount: correctCount ?? this.correctCount,
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'studySeconds': studySeconds,
        'newReviewCount': newReviewCount,
        'answeredCount': answeredCount,
        'correctCount': correctCount,
      };
}
