import '../model/question_learning_stats.dart';

/// 学習履歴。第1実装はローカル、将来 Firestore 実装に差し替え可能。
abstract class LearningHistoryRepository {
  /// 保存済みの全キー → 統計（未記録キーは呼び出し側で省略可）
  Future<Map<String, QuestionLearningStats>> loadAll();

  Future<void> recordAnswer({
    required String eraId,
    required int no,
    required bool isCorrect,
    required DateTime at,
  });

  /// 学習履歴を全件削除する。
  Future<void> deleteAll();
}
