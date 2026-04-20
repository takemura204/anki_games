import 'package:anki_games/apps/it_pass/features/filter/model/quiz_order_mode.dart';
import 'package:anki_games/apps/it_pass/features/learning/model/learning_level.dart';
import 'package:anki_games/apps/it_pass/features/quiz/model/exam_meta.dart';

class QuizFilter {
  const QuizFilter({
    required this.selectedEraIds,
    this.selectedSystems = const {},
    this.selectedMajors = const {},
    this.selectedLearningLevels = const {},
    this.quizOrderMode = QuizOrderMode.random,
  });

  factory QuizFilter.defaultAll() => QuizFilter(
        selectedEraIds: ExamMeta.all.map((m) => m.eraId).toSet(),
      );

  final Set<String> selectedEraIds;
  final Set<String> selectedSystems;
  final Set<String> selectedMajors;
  /// 空集合のときは学習レベルで絞り込まない（全レベル対象）
  final Set<LearningLevel> selectedLearningLevels;
  final QuizOrderMode quizOrderMode;

  bool get isValid => selectedEraIds.isNotEmpty;

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
