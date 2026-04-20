import 'dart:async';

import 'package:anki_games/apps/it_pass/features/filter/model/quiz_filter.dart';
import 'package:anki_games/apps/it_pass/features/filter/model/quiz_order_mode.dart';
import 'package:anki_games/apps/it_pass/features/filter/repository/filter_repository.dart';
import 'package:anki_games/apps/it_pass/features/learning/model/learning_level.dart';
import 'package:anki_games/apps/it_pass/features/learning/repository/local_learning_history_repository.dart';
import 'package:anki_games/apps/it_pass/features/quiz/model/exam_meta.dart';
import 'package:anki_games/apps/it_pass/features/quiz/repository/quiz_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FilterState {
  const FilterState({
    required this.selectedEraIds,
    this.selectedSystems = const {},
    this.selectedMajors = const {},
    this.selectedLearningLevels = const {},
    this.quizOrderMode = QuizOrderMode.random,
    this.expandedSystems = const {},
    this.isApplying = false,
    this.applyValidationMessage,
    this.matchCount,
  });

  final Set<String> selectedEraIds;
  final Set<String> selectedSystems;
  final Set<String> selectedMajors;
  final Set<LearningLevel> selectedLearningLevels;
  final QuizOrderMode quizOrderMode;
  final Set<String> expandedSystems;
  final bool isApplying;

  /// 適用ボタン検証エラー（条件変更でクリア）
  final String? applyValidationMessage;

  /// 現在の条件での該当問題数（初回計算前は null）
  final int? matchCount;

  bool get canApply => selectedEraIds.isNotEmpty;

  QuizFilter toFilter() => QuizFilter(
        selectedEraIds: selectedEraIds,
        selectedSystems: selectedSystems,
        selectedMajors: selectedMajors,
        selectedLearningLevels: selectedLearningLevels,
        quizOrderMode: quizOrderMode,
      );

  FilterState copyWith({
    Set<String>? selectedEraIds,
    Set<String>? selectedSystems,
    Set<String>? selectedMajors,
    Set<LearningLevel>? selectedLearningLevels,
    QuizOrderMode? quizOrderMode,
    Set<String>? expandedSystems,
    bool? isApplying,
    String? applyValidationMessage,
    bool clearApplyValidationMessage = false,
    int? matchCount,
  }) {
    return FilterState(
      selectedEraIds: selectedEraIds ?? this.selectedEraIds,
      selectedSystems: selectedSystems ?? this.selectedSystems,
      selectedMajors: selectedMajors ?? this.selectedMajors,
      selectedLearningLevels:
          selectedLearningLevels ?? this.selectedLearningLevels,
      quizOrderMode: quizOrderMode ?? this.quizOrderMode,
      expandedSystems: expandedSystems ?? this.expandedSystems,
      isApplying: isApplying ?? this.isApplying,
      applyValidationMessage: clearApplyValidationMessage
          ? null
          : (applyValidationMessage ?? this.applyValidationMessage),
      matchCount: matchCount ?? this.matchCount,
    );
  }
}

final AutoDisposeAsyncNotifierProvider<FilterViewModel, FilterState>
    filterViewModelProvider =
    AsyncNotifierProvider.autoDispose<FilterViewModel, FilterState>(
  FilterViewModel.new,
);

class FilterViewModel extends AutoDisposeAsyncNotifier<FilterState> {
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
    final cur = state.valueOrNull;
    if (cur == null) {
      return;
    }
    if (!cur.canApply) {
      if (gen != _matchCountGeneration) {
        return;
      }
      final latest = state.valueOrNull;
      if (latest == null) {
        return;
      }
      state = AsyncData(latest.copyWith(matchCount: 0));
      return;
    }
    final filter = cur.toFilter();
    final stats = await _learningRepo.loadAll();
    final n = (await _quizRepo.loadFilteredQuestions(filter, stats)).length;
    if (gen != _matchCountGeneration) {
      return;
    }
    final latest = state.valueOrNull;
    if (latest == null) {
      return;
    }
    state = AsyncData(latest.copyWith(matchCount: n));
  }

  void _scheduleMatchCountRefresh() {
    scheduleMicrotask(_refreshMatchCount);
  }

  void toggleLearningLevel(LearningLevel level) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final next = Set<LearningLevel>.from(current.selectedLearningLevels);
    if (next.contains(level)) {
      next.remove(level);
    } else {
      next.add(level);
    }
    state = AsyncData(
      current.copyWith(
        selectedLearningLevels: next,
        clearApplyValidationMessage: true,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void clearLearningLevels() {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        selectedLearningLevels: {},
        clearApplyValidationMessage: true,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void setQuizOrderMode(QuizOrderMode mode) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        quizOrderMode: mode,
        clearApplyValidationMessage: true,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void toggleEra(String eraId) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final ids = Set<String>.from(current.selectedEraIds);
    if (ids.contains(eraId)) {
      ids.remove(eraId);
    } else {
      ids.add(eraId);
    }
    state = AsyncData(
      current.copyWith(
        selectedEraIds: ids,
        clearApplyValidationMessage: true,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void selectAllEras() {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        selectedEraIds: ExamMeta.all.map((m) => m.eraId).toSet(),
        clearApplyValidationMessage: true,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void clearAllEras() {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncData(
      current.copyWith(
        selectedEraIds: {},
        clearApplyValidationMessage: true,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void toggleSystem(String system) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final systems = Set<String>.from(current.selectedSystems);
    final majors = Set<String>.from(current.selectedMajors);
    if (systems.contains(system)) {
      systems.remove(system);
      majors.removeAll(ExamMeta.categoryTree[system] ?? []);
    } else {
      systems.add(system);
    }
    state = AsyncData(
      current.copyWith(
        selectedSystems: systems,
        selectedMajors: majors,
        clearApplyValidationMessage: true,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void toggleMajor(String major) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final majors = Set<String>.from(current.selectedMajors);
    if (majors.contains(major)) {
      majors.remove(major);
    } else {
      majors.add(major);
    }
    state = AsyncData(
      current.copyWith(
        selectedMajors: majors,
        clearApplyValidationMessage: true,
      ),
    );
    _scheduleMatchCountRefresh();
  }

  void toggleSystemExpansion(String system) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    final expanded = Set<String>.from(current.expandedSystems);
    if (expanded.contains(system)) {
      expanded.remove(system);
    } else {
      expanded.add(system);
    }
    state = AsyncData(current.copyWith(expandedSystems: expanded));
  }

  Future<bool> apply() async {
    final current = state.valueOrNull;
    if (current == null || !current.canApply) {
      return false;
    }
    state = AsyncData(
      current.copyWith(
        isApplying: true,
        clearApplyValidationMessage: true,
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
        clearApplyValidationMessage: true,
        matchCount: count,
      ),
    );
    return true;
  }
}
