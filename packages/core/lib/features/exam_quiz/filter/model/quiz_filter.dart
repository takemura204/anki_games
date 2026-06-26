import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'quiz_order_mode.dart';

class QuizFilter {
  const QuizFilter({
    required this.selectedEraIds,
    this.selectedSystems = const {},
    this.selectedMajors = const {},
    this.selectedLearningLevels = const {},
    this.quizOrderMode = QuizOrderMode.random,
  });

  final Set<String> selectedEraIds;
  final Set<String> selectedSystems;
  final Set<String> selectedMajors;

  /// 空集合のときは学習レベルで絞り込まない（全レベル対象）
  final Set<LearningLevel> selectedLearningLevels;
  final QuizOrderMode quizOrderMode;

  bool get isValid => selectedEraIds.isNotEmpty;

  /// フィルター内容を一意に表す文字列。resume データの整合性チェックに使用。
  String get hash {
    final eraIds = (selectedEraIds.toList()..sort()).join(',');
    final systems = (selectedSystems.toList()..sort()).join(',');
    final majors = (selectedMajors.toList()..sort()).join(',');
    final levels =
        (selectedLearningLevels.map((l) => l.name).toList()..sort()).join(',');
    return '$eraIds|$systems|$majors|$levels|${quizOrderMode.name}';
  }

  QuizFilter copyWith({
    Set<String>? selectedEraIds,
    Set<String>? selectedSystems,
    Set<String>? selectedMajors,
    Set<LearningLevel>? selectedLearningLevels,
    QuizOrderMode? quizOrderMode,
  }) {
    return QuizFilter(
      selectedEraIds: selectedEraIds ?? this.selectedEraIds,
      selectedSystems: selectedSystems ?? this.selectedSystems,
      selectedMajors: selectedMajors ?? this.selectedMajors,
      selectedLearningLevels:
          selectedLearningLevels ?? this.selectedLearningLevels,
      quizOrderMode: quizOrderMode ?? this.quizOrderMode,
    );
  }
}
