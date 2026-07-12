import 'package:core/config/brand/brand_config.dart';
import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/quiz_filter.dart';
import '../model/quiz_order_mode.dart';

part 'filter_repository.g.dart';

class FilterRepository {
  FilterRepository({required String prefsPrefix}) : _prefix = prefsPrefix;

  final String _prefix;

  String get _keyEraIds => '${_prefix}_filter_era_ids';
  String get _keySystems => '${_prefix}_filter_systems';
  String get _keyMajors => '${_prefix}_filter_majors';
  String get _keyOrderMode => '${_prefix}_filter_order_mode';
  String get _keyLearningLevels => '${_prefix}_filter_learning_levels';

  /// [allEraIds] は初回起動時のデフォルト値として使用する。
  Future<QuizFilter> load({required Set<String> allEraIds}) async {
    final prefs = await SharedPreferences.getInstance();
    final eraIds = prefs.getStringList(_keyEraIds);
    final systems = prefs.getStringList(_keySystems);
    final majors = prefs.getStringList(_keyMajors);

    final levelNames = prefs.getStringList(_keyLearningLevels);

    return QuizFilter(
      selectedEraIds:
          eraIds?.toSet() ?? allEraIds,
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

@Riverpod(keepAlive: true)
FilterRepository filterRepository(Ref ref) {
  final prefix = ref.watch(brandConfigProvider).analyticsBrandKey;
  return FilterRepository(prefsPrefix: prefix);
}
