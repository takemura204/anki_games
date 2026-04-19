import 'package:anki_games/apps/it_pass/features/quiz/model/exam_meta.dart';

class QuizFilter {
  const QuizFilter({
    required this.selectedEraIds,
    this.selectedSystems = const {},
    this.selectedMajors = const {},
  });

  factory QuizFilter.defaultAll() => QuizFilter(
        selectedEraIds: ExamMeta.all.map((m) => m.eraId).toSet(),
      );

  final Set<String> selectedEraIds;
  final Set<String> selectedSystems;
  final Set<String> selectedMajors;

  bool get isValid => selectedEraIds.isNotEmpty;

  QuizFilter copyWith({
    Set<String>? selectedEraIds,
    Set<String>? selectedSystems,
    Set<String>? selectedMajors,
  }) {
    return QuizFilter(
      selectedEraIds: selectedEraIds ?? this.selectedEraIds,
      selectedSystems: selectedSystems ?? this.selectedSystems,
      selectedMajors: selectedMajors ?? this.selectedMajors,
    );
  }
}
