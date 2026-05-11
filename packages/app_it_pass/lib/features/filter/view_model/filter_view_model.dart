import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../learning/model/learning_level.dart';
import '../../learning/providers/learning_history_provider.dart';
import '../../quiz/model/exam_meta.dart';
import '../../quiz/repository/quiz_repository.dart';
import '../model/quiz_filter.dart';
import '../model/quiz_order_mode.dart';
import '../repository/filter_repository.dart';

part 'filter_view_model.freezed.dart';
part 'filter_view_model.g.dart';

@freezed
abstract class FilterState with _$FilterState {
  const FilterState._();

  const factory FilterState({
    required Set<String> selectedEraIds,
    @Default(<String>{}) Set<String> selectedSystems,
    @Default(<String>{}) Set<String> selectedMajors,
    @Default(<LearningLevel>{}) Set<LearningLevel> selectedLearningLevels,
    @Default(QuizOrderMode.random) QuizOrderMode quizOrderMode,
    @Default(<String>{}) Set<String> expandedSystems,
    @Default(false) bool isApplying,
    String? applyValidationMessage,
    int? matchCount,
  }) = _FilterState;

  bool get hasEraSelected => selectedEraIds.isNotEmpty;

  bool get canApply => hasEraSelected && matchCount != 0;

  String get buttonText {
    if (!hasEraSelected) return '試験回を選択してください';
    if (matchCount == 0) return '条件に合う問題がありません';
    return 'この設定で出題する';
  }

  QuizFilter toFilter() => QuizFilter(
        selectedEraIds: selectedEraIds,
        selectedSystems: selectedSystems,
        selectedMajors: selectedMajors,
        selectedLearningLevels: selectedLearningLevels,
        quizOrderMode: quizOrderMode,
      );
}

@riverpod
class FilterViewModel extends _$FilterViewModel {
  final _repo = FilterRepository();
  final _quizRepo = QuizRepository();

  var _matchCountGeneration = 0;

  @override
  Future<FilterState> build() async {
    final filter = await _repo.load();
    final effectiveSystems = filter.selectedSystems.isEmpty
        ? ExamMeta.categoryTree.keys.toSet()
        : Set<String>.from(filter.selectedSystems);
    final effectiveMajors = filter.selectedSystems.isEmpty
        ? ExamMeta.categoryTree.values.expand((m) => m).toSet()
        : Set<String>.from(filter.selectedMajors);
    final effectiveLevels = filter.selectedLearningLevels.isEmpty
        ? LearningLevel.values.toSet()
        : Set<LearningLevel>.from(filter.selectedLearningLevels);
    final s = FilterState(
      selectedEraIds: Set.from(filter.selectedEraIds),
      selectedSystems: effectiveSystems,
      selectedMajors: effectiveMajors,
      selectedLearningLevels: effectiveLevels,
      quizOrderMode: filter.quizOrderMode,
    );
    scheduleMicrotask(_refreshMatchCount);
    return s;
  }

  Future<void> _refreshMatchCount() async {
    final gen = ++_matchCountGeneration;
    final cur = state.value;
    if (cur == null) return;
    if (!cur.hasEraSelected) {
      if (gen != _matchCountGeneration) return;
      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(latest.copyWith(matchCount: 0));
      return;
    }
    final filter = cur.toFilter();
    final stats = await ref.read(learningHistoryRepositoryProvider).loadAll();
    final n = (await _quizRepo.loadFilteredQuestions(filter, stats)).length;
    if (gen != _matchCountGeneration) return;
    final latest = state.value;
    if (latest == null) return;
    state = AsyncData(latest.copyWith(matchCount: n));
  }

  void _scheduleMatchCountRefresh() {
    scheduleMicrotask(_refreshMatchCount);
  }

  void toggleLearningLevel(LearningLevel level) {
    final current = state.value;
    if (current == null) return;
    final next = Set<LearningLevel>.from(current.selectedLearningLevels);
    if (next.contains(level)) {
      next.remove(level);
    } else {
      next.add(level);
    }
    state = AsyncData(
      current.copyWith(
        selectedLearningLevels: next,
        applyValidationMessage: null,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void selectAllLearningLevels() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        selectedLearningLevels: LearningLevel.values.toSet(),
        applyValidationMessage: null,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void clearLearningLevels() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        selectedLearningLevels: <LearningLevel>{},
        applyValidationMessage: null,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void setQuizOrderMode(QuizOrderMode mode) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        quizOrderMode: mode,
        applyValidationMessage: null,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void toggleEra(String eraId) {
    final current = state.value;
    if (current == null) return;
    final ids = Set<String>.from(current.selectedEraIds);
    if (ids.contains(eraId)) {
      ids.remove(eraId);
    } else {
      ids.add(eraId);
    }
    state = AsyncData(
      current.copyWith(
        selectedEraIds: ids,
        applyValidationMessage: null,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void selectAllEras() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        selectedEraIds: ExamMeta.all.map((m) => m.eraId).toSet(),
        applyValidationMessage: null,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void clearAllEras() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        selectedEraIds: <String>{},
        applyValidationMessage: null,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void toggleSystem(String system) {
    final current = state.value;
    if (current == null) return;
    final systems = Set<String>.from(current.selectedSystems);
    final majors = Set<String>.from(current.selectedMajors);
    final expanded = Set<String>.from(current.expandedSystems);
    final systemMajors = ExamMeta.categoryTree[system] ?? <String>[];

    if (systems.contains(system)) {
      systems.remove(system);
      majors.removeAll(systemMajors);
      expanded.remove(system);
    } else {
      systems.add(system);
      majors.addAll(systemMajors);
      expanded.add(system);
    }
    state = AsyncData(
      current.copyWith(
        selectedSystems: systems,
        selectedMajors: majors,
        expandedSystems: expanded,
        applyValidationMessage: null,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void selectAllSystems() {
    final current = state.value;
    if (current == null) return;
    final allSystems = ExamMeta.categoryTree.keys.toSet();
    final allMajors =
        ExamMeta.categoryTree.values.expand((m) => m).toSet();
    state = AsyncData(
      current.copyWith(
        selectedSystems: allSystems,
        selectedMajors: allMajors,
        expandedSystems: allSystems,
        applyValidationMessage: null,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void clearAllSystems() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        selectedSystems: <String>{},
        selectedMajors: <String>{},
        expandedSystems: <String>{},
        applyValidationMessage: null,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void toggleMajor(String major) {
    final current = state.value;
    if (current == null) return;

    String? parentSystem;
    for (final entry in ExamMeta.categoryTree.entries) {
      if (entry.value.contains(major)) {
        parentSystem = entry.key;
        break;
      }
    }

    final majors = Set<String>.from(current.selectedMajors);
    final systems = Set<String>.from(current.selectedSystems);
    final expanded = Set<String>.from(current.expandedSystems);

    if (majors.contains(major)) {
      majors.remove(major);
      if (parentSystem != null) {
        final remaining = (ExamMeta.categoryTree[parentSystem] ?? <String>[])
            .where((m) => majors.contains(m));
        if (remaining.isEmpty) {
          systems.remove(parentSystem);
          expanded.remove(parentSystem);
        }
      }
    } else {
      majors.add(major);
      if (parentSystem != null) {
        systems.add(parentSystem);
      }
    }

    state = AsyncData(
      current.copyWith(
        selectedMajors: majors,
        selectedSystems: systems,
        expandedSystems: expanded,
        applyValidationMessage: null,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void toggleSystemExpansion(String system) {
    final current = state.value;
    if (current == null) return;
    final expanded = Set<String>.from(current.expandedSystems);
    if (expanded.contains(system)) {
      expanded.remove(system);
    } else {
      expanded.add(system);
    }
    state = AsyncData(current.copyWith(expandedSystems: expanded));
  }

  Future<bool> apply() async {
    final current = state.value;
    if (current == null || !current.canApply) return false;
    state = AsyncData(
      current.copyWith(
        isApplying: true,
        applyValidationMessage: null,
      ),
    );
    final filter = current.toFilter();
    final stats = await ref.read(learningHistoryRepositoryProvider).loadAll();
    final count = (await _quizRepo.loadFilteredQuestions(filter, stats)).length;
    if (count == 0) {
      state = AsyncData(
        current.copyWith(isApplying: false, matchCount: 0),
      );
      return false;
    }
    await _repo.save(filter);
    state = AsyncData(
      current.copyWith(
        isApplying: false,
        applyValidationMessage: null,
        matchCount: count,
      ),
    );
    return true;
  }
}
