import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../learning/model/learning_level.dart';
import '../../learning/model/question_learning_stats.dart';
import '../../learning/repository/local_learning_history_repository.dart';
import '../../quiz/repository/quiz_repository.dart';
import '../model/note_list_item.dart';
import '../repository/local_bookmark_repository.dart';

final noteSheetViewModelProvider = AsyncNotifierProvider.autoDispose<
    NoteSheetViewModel, NoteSheetReady>(NoteSheetViewModel.new);

class NoteSheetReady {
  const NoteSheetReady({
    required this.reviewItems,
    required this.bookmarkItems,
    required this.stats,
    required this.bookmarks,
  });

  /// LearningLevel が weak/fuzzy の問題
  final List<NoteListItem> reviewItems;

  /// 手動ブックマーク済みの問題
  final List<NoteListItem> bookmarkItems;

  /// 履歴タブで LearningLevel バッジを表示するために保持
  final Map<String, QuestionLearningStats> stats;

  /// 履歴タブのブックマーク初期値に使用
  final Set<String> bookmarks;
}

class NoteSheetViewModel extends AsyncNotifier<NoteSheetReady> {
  @override
  Future<NoteSheetReady> build() async {
    final bookmarksFuture = LocalBookmarkRepository().loadAll();
    final statsFuture = LocalLearningHistoryRepository().loadAll();

    final (bookmarks, stats) = await (bookmarksFuture, statsFuture).wait;

    final weakKeys = stats.entries
        .where((e) {
          final level = LearningLevel.fromStats(e.value);
          return level == LearningLevel.weak || level == LearningLevel.fuzzy;
        })
        .map((e) => e.key)
        .toSet();

    final allKeys = {...bookmarks, ...weakKeys};
    final itemsByKey = await _loadItems(allKeys, stats, bookmarks);

    final reviewItems = weakKeys
        .where((k) => itemsByKey.containsKey(k))
        .map((k) => itemsByKey[k]!)
        .toList();

    final bookmarkItems = bookmarks
        .where((k) => itemsByKey.containsKey(k))
        .map((k) => itemsByKey[k]!)
        .toList();

    return NoteSheetReady(
      reviewItems: reviewItems,
      bookmarkItems: bookmarkItems,
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
            final key =
                LocalLearningHistoryRepository.storageKey(eraId, q.no);
            result[key] = NoteListItem(
              question: q,
              level: LearningLevel.fromStats(stats[key]),
              isBookmarked: bookmarks.contains(key),
            );
          }
        } on Object {
          // 不明な eraId はスキップ
        }
      }),
    );

    return result;
  }
}
