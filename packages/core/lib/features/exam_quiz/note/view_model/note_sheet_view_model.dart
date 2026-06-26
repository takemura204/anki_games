import 'package:core/features/exam_quiz/config/exam_config.dart';
import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:core/features/exam_quiz/learning/model/question_learning_stats.dart';
import 'package:core/features/exam_quiz/learning/providers/learning_history_provider.dart';
import 'package:core/features/exam_quiz/learning/repository/local_learning_history_repository.dart'
    show LocalLearningHistoryRepository;
import 'package:core/features/exam_quiz/note/model/note_list_item.dart';
import 'package:core/features/exam_quiz/note/repository/local_bookmark_repository.dart';
import 'package:core/features/exam_quiz/note/repository/local_quiz_history_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../quiz/repository/quiz_repository.dart';

part 'note_sheet_view_model.freezed.dart';
part 'note_sheet_view_model.g.dart';

@freezed
abstract class NoteSheetReady with _$NoteSheetReady {
  const factory NoteSheetReady({
    required List<NoteListItem> reviewItems,
    required List<NoteListItem> bookmarkItems,
    required List<NoteListItem> historyItems,
    required Map<String, QuestionLearningStats> stats,
    required Set<String> bookmarks,
  }) = _NoteSheetReady;
}

@riverpod
class NoteSheetViewModel extends _$NoteSheetViewModel {
  @override
  Future<NoteSheetReady> build() async {
    final examConfig = ref.watch(examConfigProvider);
    final bookmarkRepo = LocalBookmarkRepository();
    final learningRepo = await ref.watch(learningHistoryRepositoryProvider.future);
    final historyRepo = ref.read(localQuizHistoryRepositoryProvider);

    final (bookmarks, stats, historyRecords, masteredKeys) = await (
      bookmarkRepo.loadAll(),
      learningRepo.loadAll(),
      historyRepo.loadRecent(
          ),
      learningRepo.loadMastered(),
    ).wait;

    final weakKeys = stats.entries
        .where((e) {
          if (masteredKeys.contains(e.key)) return false;
          final level = LearningLevel.fromStats(e.value);
          return level == LearningLevel.weak || level == LearningLevel.fuzzy;
        })
        .map((e) => e.key)
        .toSet();

    final reviewBookmarkKeys = {...bookmarks, ...weakKeys};
    final historyKeys = historyRecords
        .map((r) => LocalLearningHistoryRepository.storageKey(r.eraId, r.no))
        .toSet();
    final allKeys = {...reviewBookmarkKeys, ...historyKeys};
    final itemsByKey = await _loadItems(allKeys, stats, bookmarks, examConfig: examConfig);

    final reviewItems = weakKeys
        .where(itemsByKey.containsKey)
        .map((k) => itemsByKey[k]!)
        .toList();

    final bookmarkItems = bookmarks
        .where(itemsByKey.containsKey)
        .map((k) => itemsByKey[k]!)
        .toList();

    final historyItems = historyRecords
        .map((r) {
          final key = LocalLearningHistoryRepository.storageKey(r.eraId, r.no);
          final base = itemsByKey[key];
          if (base == null) return null;
          return NoteListItem(
            question: base.question,
            level: base.level,
            isBookmarked: base.isBookmarked,
            selectedLabel: r.selectedLabel,
            lastWasCorrect: r.isCorrect,
          );
        })
        .whereType<NoteListItem>()
        .toList();

    return NoteSheetReady(
      reviewItems: reviewItems,
      bookmarkItems: bookmarkItems,
      historyItems: historyItems,
      stats: stats,
      bookmarks: bookmarks,
    );
  }

  Future<Map<String, NoteListItem>> _loadItems(
    Set<String> keys,
    Map<String, QuestionLearningStats> stats,
    Set<String> bookmarks, {
    required ExamConfig examConfig,
  }) async {
    final byEra = <String, Set<int>>{};
    for (final key in keys) {
      final lastUnderscore = key.lastIndexOf('_');
      if (lastUnderscore < 0) continue;
      final eraId = key.substring(0, lastUnderscore);
      final no = int.tryParse(key.substring(lastUnderscore + 1));
      if (no == null) continue;
      byEra.putIfAbsent(eraId, () => {}).add(no);
    }

    final repo = ref.read(quizRepositoryProvider);
    final result = <String, NoteListItem>{};

    await Future.wait(
      byEra.entries.map((entry) async {
        final eraId = entry.key;
        final nos = entry.value;
        try {
          final questions = await repo.loadEra(eraId, examConfig: examConfig);
          for (final q in questions) {
            if (!nos.contains(q.no)) continue;
            final key = LocalLearningHistoryRepository.storageKey(eraId, q.no);
            final stat = stats[key];
            result[key] = NoteListItem(
              question: q,
              level: LearningLevel.fromStats(stat),
              isBookmarked: bookmarks.contains(key),
              selectedLabel: stat?.lastSelectedLabel,
            );
          }
        } on Object {
          // unknown eraId — skip
        }
      }),
    );

    return result;
  }
}
