import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'quiz_resume_repository.g.dart';

class QuizResumeData {
  const QuizResumeData({
    required this.setIndex,
    required this.questionIndex,
    required this.questionIds,
    required this.filterHash,
  });

  final int setIndex;
  final int questionIndex;

  /// 全セッションの問題 ID リスト（"eraId:no" 形式）。
  /// ランダム順など順序が変わるモードでも同じ順を復元するために保存。
  final List<String> questionIds;

  /// 保存時のフィルターハッシュ。フィルター変更を検知するために使用。
  final String filterHash;
}

class QuizResumeRepository {
  static const _keySetIndex = 'quiz_resume_set_index';
  static const _keyQuestionIndex = 'quiz_resume_question_index';
  static const _keyQuestionIds = 'quiz_resume_question_ids';
  static const _keyFilterHash = 'quiz_resume_filter_hash';

  Future<QuizResumeData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final setIndex = prefs.getInt(_keySetIndex);
    final questionIndex = prefs.getInt(_keyQuestionIndex);
    final questionIds = prefs.getStringList(_keyQuestionIds);
    final filterHash = prefs.getString(_keyFilterHash);

    if (setIndex == null ||
        questionIndex == null ||
        questionIds == null ||
        filterHash == null) {
      return null;
    }
    return QuizResumeData(
      setIndex: setIndex,
      questionIndex: questionIndex,
      questionIds: questionIds,
      filterHash: filterHash,
    );
  }

  Future<void> save({
    required int setIndex,
    required int questionIndex,
    required List<String> questionIds,
    required String filterHash,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt(_keySetIndex, setIndex),
      prefs.setInt(_keyQuestionIndex, questionIndex),
      prefs.setStringList(_keyQuestionIds, questionIds),
      prefs.setString(_keyFilterHash, filterHash),
    ]);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keySetIndex),
      prefs.remove(_keyQuestionIndex),
      prefs.remove(_keyQuestionIds),
      prefs.remove(_keyFilterHash),
    ]);
  }
}

@Riverpod(keepAlive: true)
QuizResumeRepository quizResumeRepository(Ref ref) => QuizResumeRepository();
