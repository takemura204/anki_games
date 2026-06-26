import 'dart:async';

import 'package:core/features/exam_quiz/config/exam_config.dart';
import 'package:core/features/exam_quiz/filter/model/quiz_filter.dart';
import 'package:core/features/exam_quiz/filter/model/quiz_order_mode.dart';
import 'package:core/features/exam_quiz/filter/repository/filter_repository.dart';
import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:core/features/exam_quiz/learning/providers/learning_history_provider.dart';
import 'package:core/features/exam_quiz/learning/repository/local_learning_history_repository.dart'
    show LocalLearningHistoryRepository;
import 'package:core/features/exam_quiz/model/exam_meta.dart';
import 'package:core/features/exam_quiz/quiz/repository/quiz_repository.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'filter_view_model.freezed.dart';
part 'filter_view_model.g.dart';

@freezed
abstract class FilterState with _$FilterState {

  const factory FilterState({
    required Set<String> selectedEraIds,
    required Map<String, List<String>> categoryTree,
    required Set<String> freeEraIds,
    required Set<String> sampleEraIds,
    required List<ExamMeta> availableExamList,
    @Default(<String>{}) Set<String> selectedSystems,
    @Default(<String>{}) Set<String> selectedMajors,
    @Default(<LearningLevel>{}) Set<LearningLevel> selectedLearningLevels,
    @Default(QuizOrderMode.optimized) QuizOrderMode quizOrderMode,
    @Default(<String>{}) Set<String> expandedSystems,
    @Default(false) bool isPremium,
    @Default(false) bool isApplying,
    String? applyValidationMessage,
    int? matchCount,
  }) = _FilterState;
  const FilterState._();

  bool get hasEraSelected => effectiveEraIds.isNotEmpty;

  bool get canApply => hasEraSelected && matchCount != 0;

  /// プレミアム状態に応じてアクセス可能な eraId セット。
  /// サンプル問題はプレミアム状態に関わらず常にアクセス可能。
  Set<String> get effectiveEraIds {
    if (isPremium) return selectedEraIds;
    return selectedEraIds.intersection({...freeEraIds, ...sampleEraIds});
  }

  String get buttonText {
    if (!hasEraSelected) return '試験回を選択してください';
    if (matchCount == 0) return '条件に合う問題がありません';
    return 'この設定で出題する';
  }

  QuizFilter toFilter() => QuizFilter(
        selectedEraIds: effectiveEraIds,
        selectedSystems: selectedSystems,
        selectedMajors: selectedMajors,
        selectedLearningLevels: selectedLearningLevels,
        quizOrderMode: quizOrderMode,
      );
}

@riverpod
class FilterViewModel extends _$FilterViewModel {
  FilterRepository get _repo => ref.read(filterRepositoryProvider);
  QuizRepository get _quizRepo => ref.read(quizRepositoryProvider);

  var _matchCountGeneration = 0;

  @override
  Future<FilterState> build() async {
    final examConfig = ref.watch(examConfigProvider);
    final isPremium =
        (await ref.watch(premiumViewModelProvider.future)).isPremium;

    ref.listen(premiumViewModelProvider, (_, next) {
      final current = state.value;
      if (current == null) return;
      final premium = next.asData?.value.isPremium ?? false;
      state = AsyncData(current.copyWith(isPremium: premium));
      _scheduleMatchCountRefresh();
    });

    final allEraIds = examConfig.examList.map((m) => m.eraId).toSet();
    final filter = await _repo.load(allEraIds: allEraIds);
    final effectiveSystems = filter.selectedSystems.isEmpty
        ? examConfig.categoryTree.keys.toSet()
        : Set<String>.from(filter.selectedSystems);
    final effectiveMajors = filter.selectedSystems.isEmpty
        ? examConfig.categoryTree.values.expand((m) => m).toSet()
        : Set<String>.from(filter.selectedMajors);
    final effectiveLevels = filter.selectedLearningLevels.isEmpty
        ? LearningLevel.values.toSet()
        : Set<LearningLevel>.from(filter.selectedLearningLevels);
    final sampleEraIds = examConfig.examList
        .where((m) => m.isSample)
        .map((m) => m.eraId)
        .toSet();
    final s = FilterState(
      selectedEraIds: Set.from(filter.selectedEraIds),
      categoryTree: examConfig.categoryTree,
      freeEraIds: examConfig.freeEraIds,
      sampleEraIds: sampleEraIds,
      availableExamList: examConfig.availableExamList,
      selectedSystems: effectiveSystems,
      selectedMajors: effectiveMajors,
      selectedLearningLevels: effectiveLevels,
      quizOrderMode: filter.quizOrderMode,
      isPremium: isPremium,
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
    final examConfig = ref.read(examConfigProvider);
    final stats = await (ref.read(learningHistoryRepositoryProvider).asData?.value ??
            LocalLearningHistoryRepository())
        .loadAll();
    final n = (await _quizRepo.loadFilteredQuestions(
      filter,
      stats,
      examConfig: examConfig,
    )).length;
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
    final ids = current.isPremium
        ? current.availableExamList.map((m) => m.eraId).toSet()
        : current.freeEraIds;
    state = AsyncData(
      current.copyWith(
        selectedEraIds: ids,
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
    final systemMajors = current.categoryTree[system] ?? <String>[];

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
    final allSystems = current.categoryTree.keys.toSet();
    final allMajors =
        current.categoryTree.values.expand((m) => m).toSet();
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
    for (final entry in current.categoryTree.entries) {
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
        final remaining = (current.categoryTree[parentSystem] ?? <String>[])
            .where(majors.contains);
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
    final examConfig = ref.read(examConfigProvider);
    final stats = await (ref.read(learningHistoryRepositoryProvider).asData?.value ??
            LocalLearningHistoryRepository())
        .loadAll();
    final count = (await _quizRepo.loadFilteredQuestions(
      filter,
      stats,
      examConfig: examConfig,
    )).length;
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
