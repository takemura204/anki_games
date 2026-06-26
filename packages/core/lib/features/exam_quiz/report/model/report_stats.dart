class ReportStats {
  const ReportStats({
    required this.totalAnswered,
    required this.todayAnswered,
    required this.totalCorrect,
    required this.todayCorrect,
    required this.reviewCount,
    required this.todayNewReview,
    required this.totalStudySec,
    required this.todayStudySec,
    required this.studyTimeDaily,
    required this.answeredDaily,
    required this.correctDaily,
    required this.newReviewDaily,
  });

  final int totalAnswered;
  final int todayAnswered;
  final int totalCorrect;
  final int todayCorrect;

  /// wrongCount > 0 の問題数（累計）
  final int reviewCount;

  /// 今日初めて不正解になった問題数
  final int todayNewReview;

  final int totalStudySec;
  final int todayStudySec;

  final List<double> studyTimeDaily;
  final List<double> answeredDaily;
  final List<double> correctDaily;
  final List<double> newReviewDaily;

  // ─── 表示用ヘルパー ──────────────────────────────────────────

  static String formatCount(int count) {
    if (count >= 1000) {
      final thousands = count ~/ 1000;
      final rest = count % 1000;
      return '$thousands,${rest.toString().padLeft(3, '0')}';
    }
    return '$count';
  }

  static ({String value, String unit}) studyTimePrimary(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    if (h == 0) return (value: '$m', unit: '分');
    return (value: '$h', unit: '時間');
  }

  static ({String value, String unit})? studyTimeSecondary(int totalSec) {
    final h = totalSec ~/ 3600;
    if (h == 0) return null;
    final m = (totalSec % 3600) ~/ 60;
    return (value: '$m', unit: '分');
  }

  static String formatStudyTimeDelta(int deltaSec) {
    final h = deltaSec ~/ 3600;
    final m = (deltaSec % 3600) ~/ 60;
    if (deltaSec == 0) return '0';
    if (h == 0) return '$m';
    return '$h時間$m';
  }
}
