import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../learning/model/learning_level.dart';
import '../../learning/repository/local_learning_history_repository.dart';
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

  bool get canApply => selectedEraIds.isNotEmpty;

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
  final _learningRepo = LocalLearningHistoryRepository();

  var _matchCountGeneration = 0;

  @override
  Future<FilterState> build() async {
    final filter = await _repo.load();
    final s = FilterState(
      selectedEraIds: Set.from(filter.selectedEraIds),
      selectedSystems: Set.from(filter.selectedSystems),
      selectedMajors: Set.from(filter.selectedMajors),
      selectedLearningLevels: Set.from(filter.selectedLearningLevels),
      quizOrderMode: filter.quizOrderMode,
    );
    scheduleMicrotask(_refreshMatchCount);
    return s;
  }

  Future<void> _refreshMatchCount() async {
    final gen = ++_matchCountGeneration;
    final cur = state.value;
    if (cur == null) return;
    if (!cur.canApply) {
      if (gen != _matchCountGeneration) return;
      final latest = state.value;
      if (latest == null) return;
      state = AsyncData(latest.copyWith(matchCount: 0));
      return;
    }
    final filter = cur.toFilter();
    final stats = await _learningRepo.loadAll();
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
    if (systems.contains(system)) {
      systems.remove(system);
      majors.removeAll(ExamMeta.categoryTree[system] ?? <String>[]);
    } else {
      systems.add(system);
    }
    state = AsyncData(
      current.copyWith(
        selectedSystems: systems,
        selectedMajors: majors,
        applyValidationMessage: null,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void toggleMajor(String major) {
    final current = state.value;
    if (current == null) return;
    final majors = Set<String>.from(current.selectedMajors);
    if (majors.contains(major)) {
      majors.remove(major);
    } else {
      majors.add(major);
    }
    state = AsyncData(
      current.copyWith(
        selectedMajors: majors,
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
    final stats = await _learningRepo.loadAll();
    final count = (await _quizRepo.loadFilteredQuestions(filter, stats)).length;
    if (count == 0) {
      state = AsyncData(
        current.copyWith(
          isApplying: false,
          matchCount: 0,
          applyValidationMessage:
              '条件に合う問題がありません。学習レベル・分野・試験回の組み合わせを見直してください。',
        ),
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
