import 'package:anki_games/apps/it_pass/features/filter/model/quiz_filter.dart';
import 'package:anki_games/apps/it_pass/features/filter/model/quiz_order_mode.dart';
import 'package:anki_games/apps/it_pass/features/learning/model/learning_level.dart';
import 'package:anki_games/apps/it_pass/features/quiz/model/exam_meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilterRepository {
  static const _keyEraIds = 'it_pass_filter_era_ids';
  static const _keySystems = 'it_pass_filter_systems';
  static const _keyMajors = 'it_pass_filter_majors';
  static const _keyOrderMode = 'it_pass_filter_order_mode';
  static const _keyLearningLevels = 'it_pass_filter_learning_levels';

  Future<QuizFilter> load() async {
    final prefs = await SharedPreferences.getInstance();
    final eraIds = prefs.getStringList(_keyEraIds);
    final systems = prefs.getStringList(_keySystems);
    final majors = prefs.getStringList(_keyMajors);

    final levelNames = prefs.getStringList(_keyLearningLevels);

    return QuizFilter(
      selectedEraIds:
          eraIds?.toSet() ?? ExamMeta.all.map((m) => m.eraId).toSet(),
      selectedSystems: systems?.toSet() ?? const {},
      selectedMajors: majors?.toSet() ?? const {},
      selectedLearningLevels: parseLearningLevelsFromStorage(levelNames),
      quizOrderMode: QuizOrderModeStorage.fromStorage(
        prefs.getString(_keyOrderMode),
      ),
    );
  }

  Future<void> save(QuizFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyEraIds, filter.selectedEraIds.toList());
    await prefs.setStringList(_keySystems, filter.selectedSystems.toList());
    await prefs.setStringList(_keyMajors, filter.selectedMajors.toList());
    await prefs.setString(_keyOrderMode, filter.quizOrderMode.name);
    await prefs.setStringList(
      _keyLearningLevels,
      filter.selectedLearningLevels.map((e) => e.name).toList(),
    );
  }
}
