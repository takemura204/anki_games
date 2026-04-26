import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../filter/model/quiz_filter.dart';
import '../../learning/model/learning_level.dart';
import '../../learning/model/question_learning_stats.dart';
import '../../learning/repository/local_learning_history_repository.dart';
import '../model/exam_meta.dart';
import '../model/question.dart';
import '../services/quiz_question_ordering.dart';

class QuizRepository {
  /// 1 セッションあたりの最大出題数（それ以下なら全件）
  static const maxQuestionsPerSession = 10;

  /// eraId → 問題一覧のメモリキャッシュ。
  /// アプリ起動中は保持し続け、フィルター変更時の再ロードを不要にする。
  static final Map<String, List<Question>> _questionCache = {};

  /// eraId 文字列から問題をロードする（NoteSheet などで利用）。
  Future<List<Question>> loadEra(String eraId) async {
    final meta = ExamMeta.all.where((m) => m.eraId == eraId).firstOrNull;
    if (meta == null) return [];
    return _loadEra(meta);
  }

  /// 単一 eraId の問題をロードする（キャッシュ済みなら即返却）。
  Future<List<Question>> _loadEra(ExamMeta meta) async {
    final cached = _questionCache[meta.eraId];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(meta.assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    late final List<Question> questions;
    try {
      questions = (json['questions'] as List<dynamic>)
          .map(
            (e) => Question.fromJson(
              e as Map<String, dynamic>,
              eraId: meta.eraId,
              examDisplayName: meta.displayName,
            ),
          )
          .toList();
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[QuizRepository] 問題JSONのパースに失敗: eraId=${meta.eraId} '
          'path=${meta.assetPath}',
        );
        debugPrint('[QuizRepository] $e');
        debugPrint('$st');
      }
      rethrow;
    }

    _questionCache[meta.eraId] = questions;
    return questions;
  }

  /// 出題順を適用する前の、条件一致問題一覧（件数検証用にも使う）。
  /// 選択された era を Future.wait で並列ロードする。
  Future<List<Question>> loadFilteredQuestions(
    QuizFilter filter,
    Map<String, QuestionLearningStats> learningStats,
  ) async {
    final targets =
        ExamMeta.all.where((m) => filter.selectedEraIds.contains(m.eraId));

    final perEra = await Future.wait(targets.map(_loadEra));
    final all = perEra.expand((q) => q).toList();

    var filtered = all.where((q) {
      if (filter.selectedSystems.isNotEmpty &&
          !filter.selectedSystems.contains(q.system)) {
        return false;
      }
      if (filter.selectedMajors.isNotEmpty &&
          !filter.selectedMajors.contains(q.major)) {
        return false;
      }
      return true;
    }).toList();

    if (filter.selectedLearningLevels.isNotEmpty) {
      filtered = filtered.where((q) {
        final key = LocalLearningHistoryRepository.storageKey(q.eraId, q.no);
        final level = LearningLevel.fromStats(learningStats[key]);
        return filter.selectedLearningLevels.contains(level);
      }).toList();
    }

    return filtered;
  }

  /// フィルター後の全問題を順序適用して返す（上限なし）。
  /// セット分割は [QuizSession] が担う。
  Future<List<Question>> loadSession(
    QuizFilter filter,
    Map<String, QuestionLearningStats> learningStats,
  ) async {
    final filtered = await loadFilteredQuestions(filter, learningStats);
    return QuizQuestionOrdering.apply(filtered, filter, learningStats);
  }
}
