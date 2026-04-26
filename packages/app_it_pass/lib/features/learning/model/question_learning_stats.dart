/// 1問あたりの集計。Firestore では docId = `${eraId}_$no` を想定。
class QuestionLearningStats {
  const QuestionLearningStats({
    this.correctCount = 0,
    this.wrongCount = 0,
    this.lastAnsweredAt,
    this.lastWasCorrect,
    this.lastSelectedLabel,
  });

  factory QuestionLearningStats.fromJson(Map<String, dynamic> json) {
    return QuestionLearningStats(
      correctCount: json['correctCount'] as int? ?? 0,
      wrongCount: json['wrongCount'] as int? ?? 0,
      lastAnsweredAt: json['lastAnsweredAt'] != null
          ? DateTime.tryParse(json['lastAnsweredAt'] as String)
          : null,
      lastWasCorrect: json['lastWasCorrect'] as bool?,
      lastSelectedLabel: json['lastSelectedLabel'] as String?,
    );
  }

  final int correctCount;
  final int wrongCount;
  final DateTime? lastAnsweredAt;
  final bool? lastWasCorrect;

  /// 最後に選択した選択肢ラベル（復習タブで前回の回答を表示するために使用）
  final String? lastSelectedLabel;

  QuestionLearningStats copyWith({
    int? correctCount,
    int? wrongCount,
    DateTime? lastAnsweredAt,
    bool? lastWasCorrect,
    String? lastSelectedLabel,
  }) {
    return QuestionLearningStats(
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      lastAnsweredAt: lastAnsweredAt ?? this.lastAnsweredAt,
      lastWasCorrect: lastWasCorrect ?? this.lastWasCorrect,
      lastSelectedLabel: lastSelectedLabel ?? this.lastSelectedLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'lastAnsweredAt': lastAnsweredAt?.toIso8601String(),
        'lastWasCorrect': lastWasCorrect,
        'lastSelectedLabel': lastSelectedLabel,
      };
}
