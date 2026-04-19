import 'package:anki_games/apps/it_pass/features/quiz/model/exam_meta.dart';
import 'package:anki_games/apps/it_pass/features/quiz/model/quiz_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilterRepository {
  static const _keyEraIds = 'it_pass_filter_era_ids';
  static const _keySystems = 'it_pass_filter_systems';
  static const _keyMajors = 'it_pass_filter_majors';

  Future<QuizFilter> load() async {
    final prefs = await SharedPreferences.getInstance();
    final eraIds = prefs.getStringList(_keyEraIds);
    final systems = prefs.getStringList(_keySystems);
    final majors = prefs.getStringList(_keyMajors);

    return QuizFilter(
      selectedEraIds: eraIds?.toSet() ??
          ExamMeta.all.map((m) => m.eraId).toSet(),
      selectedSystems: systems?.toSet() ?? const {},
      selectedMajors: majors?.toSet() ?? const {},
    );
  }

  Future<void> save(QuizFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyEraIds, filter.selectedEraIds.toList());
    await prefs.setStringList(_keySystems, filter.selectedSystems.toList());
    await prefs.setStringList(_keyMajors, filter.selectedMajors.toList());
  }
}
