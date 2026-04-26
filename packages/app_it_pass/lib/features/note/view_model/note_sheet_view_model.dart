import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../learning/model/learning_level.dart';
import '../../learning/model/question_learning_stats.dart';
import '../../learning/repository/local_learning_history_repository.dart';
import '../../quiz/repository/quiz_repository.dart';
import '../model/note_list_item.dart';
import '../repository/local_bookmark_repository.dart';
import '../repository/local_quiz_history_repository.dart';

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
    final bookmarkRepo = LocalBookmarkRepository();
    final learningRepo = LocalLearningHistoryRepository();
    final historyRepo = LocalQuizHistoryRepository();

    final (bookmarks, stats, historyRecords, masteredKeys) = await (
      bookmarkRepo.loadAll(),
      learningRepo.loadAll(),
      historyRepo.loadRecent(
          limit: LocalQuizHistoryRepository.defaultDisplayLimit),
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
    final itemsByKey = await _loadItems(allKeys, stats, bookmarks);

    final reviewItems = weakKeys
        .where((k) => itemsByKey.containsKey(k))
        .map((k) => itemsByKey[k]!)
        .toList();

    final bookmarkItems = bookmarks
        .where((k) => itemsByKey.containsKey(k))
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
    Set<String> bookmarks,
  ) async {
    final byEra = <String, Set<int>>{};
    for (final key in keys) {
      final lastUnderscore = key.lastIndexOf('_');
      if (lastUnderscore < 0) continue;
      final eraId = key.substring(0, lastUnderscore);
      final no = int.tryParse(key.substring(lastUnderscore + 1));
      if (no == null) continue;
      byEra.putIfAbsent(eraId, () => {}).add(no);
    }

    final repo = QuizRepository();
    final result = <String, NoteListItem>{};

    await Future.wait(
      byEra.entries.map((entry) async {
        final eraId = entry.key;
        final nos = entry.value;
        try {
          final questions = await repo.loadEra(eraId);
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
