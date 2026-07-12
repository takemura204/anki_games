class QuizHistoryRecord {
  const QuizHistoryRecord({
    required this.eraId,
    required this.no,
    required this.selectedLabel,
    required this.isCorrect,
    required this.answeredAt,
  });

  factory QuizHistoryRecord.fromJson(Map<String, dynamic> json) {
    return QuizHistoryRecord(
      eraId: json['eraId'] as String,
      no: json['no'] as int,
      selectedLabel: json['selectedLabel'] as String,
      isCorrect: json['isCorrect'] as bool,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
    );
  }

  final String eraId;
  final int no;
  final String selectedLabel;
  final bool isCorrect;
  final DateTime answeredAt;

  Map<String, dynamic> toJson() => {
        'eraId': eraId,
        'no': no,
        'selectedLabel': selectedLabel,
        'isCorrect': isCorrect,
        'answeredAt': answeredAt.toIso8601String(),
      };
}
