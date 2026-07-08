import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// クイズセットの累計完了回数を永続化するリポジトリ。
///
/// セット完了（結果ページ到達）ごとに [increment] を呼ぶ。
/// レビュー訴求（2セット目以降が条件）などに使用する。
class LocalQuizSessionCountRepository {
  static const _key = 'quiz_completed_set_count';

  Future<int> getCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  Future<void> increment() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_key) ?? 0;
    await prefs.setInt(_key, current + 1);
  }
}

final quizSessionCountRepositoryProvider =
    Provider<LocalQuizSessionCountRepository>(
      (_) => LocalQuizSessionCountRepository(),
    );
