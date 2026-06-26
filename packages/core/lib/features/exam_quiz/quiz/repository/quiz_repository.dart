import 'dart:convert';

import 'package:core/features/exam_quiz/config/exam_config.dart';
import 'package:core/features/exam_quiz/filter/model/quiz_filter.dart';
import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:core/features/exam_quiz/learning/model/question_learning_stats.dart';
import 'package:core/features/exam_quiz/learning/repository/local_learning_history_repository.dart';
import 'package:core/features/exam_quiz/model/exam_meta.dart';
import 'package:core/features/exam_quiz/model/question.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../datasource/quiz_local_datasource.dart';
import 'quiz_question_ordering.dart';

part 'quiz_repository.g.dart';

/// クイズデータが未ダウンロードのときにスローされる例外。
class QuizDataNotCachedException implements Exception {
  const QuizDataNotCachedException(this.eraId);
  final String eraId;

  @override
  String toString() =>
      'QuizDataNotCachedException: $eraId のデータが端末にありません。'
      'ネットワーク接続を確認してください。';
}

class QuizRepository {
  QuizRepository({QuizLocalDatasource? localDatasource})
      : _local = localDatasource ?? QuizLocalDatasource.instance;

  final QuizLocalDatasource _local;

  /// eraId → 問題一覧のメモリキャッシュ。
  /// アプリ起動中は保持し続け、フィルター変更時の再ロードを不要にする。
  final Map<String, List<Question>> _questionCache = {};

  /// eraId 文字列から問題をロードする（NoteSheet などで利用）。
  Future<List<Question>> loadEra(
    String eraId, {
    required ExamConfig examConfig,
  }) async {
    final meta =
        examConfig.examList.where((m) => m.eraId == eraId).firstOrNull;
    if (meta == null) return [];
    return _loadEra(meta, examConfig.examTypeKey);
  }

  Future<List<Question>> _loadEra(ExamMeta meta, String examTypeKey) async {
    final cached = _questionCache[meta.eraId];
    if (cached != null) return cached;

    final raw = await _local.readFile(examTypeKey, meta.fileName);
    if (raw == null) {
      throw QuizDataNotCachedException(meta.eraId);
    }

    late final List<Question> questions;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
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
          'fileName=${meta.fileName}',
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
  Future<List<Question>> loadFilteredQuestions(
    QuizFilter filter,
    Map<String, QuestionLearningStats> learningStats, {
    required ExamConfig examConfig,
  }) async {
    final targets = examConfig.examList
        .where((m) => filter.selectedEraIds.contains(m.eraId));

    final perEra = await Future.wait(
      targets.map((m) => _loadEra(m, examConfig.examTypeKey)),
    );
    final all = perEra.expand((q) => q).toList();

    if (filter.selectedSystems.isEmpty) return [];
    if (filter.selectedLearningLevels.isEmpty) return [];

    final filtered = all.where((q) {
      if (!filter.selectedSystems.contains(q.system)) return false;
      if (q.major.isEmpty) return true;
      if (filter.selectedMajors.isNotEmpty &&
          !filter.selectedMajors.contains(q.major)) {
        return false;
      }
      return true;
    }).toList();

    return filtered.where((q) {
      final key = LocalLearningHistoryRepository.storageKey(q.eraId, q.no);
      final level = LearningLevel.fromStats(learningStats[key]);
      return filter.selectedLearningLevels.contains(level);
    }).toList();
  }

  /// フィルター後の全問題を順序適用して返す（上限なし）。
  Future<List<Question>> loadSession(
    QuizFilter filter,
    Map<String, QuestionLearningStats> learningStats, {
    required ExamConfig examConfig,
  }) async {
    final filtered = await loadFilteredQuestions(
      filter,
      learningStats,
      examConfig: examConfig,
    );
    return QuizQuestionOrdering.apply(
      filtered,
      filter,
      learningStats,
      eraIdOrder: examConfig.examList.map((m) => m.eraId).toList(),
    );
  }

  /// メモリキャッシュをクリアする（sync 更新後に呼ぶ）。
  void clearCache() => _questionCache.clear();
}

@Riverpod(keepAlive: true)
QuizRepository quizRepository(Ref ref) => QuizRepository();
