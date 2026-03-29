import 'package:mono_games/features/quiz/db/app_database.dart';

/// 単語学習履歴の永続化インターフェース。
///
/// ローカル実装 (LocalWordRecordRepository) を使用。
/// 将来 Firestore へ移行する場合はこのインターフェースの実装を差し替える。
abstract interface class WordRecordRepository {
  /// 全単語レコードを取得する。
  Future<List<WordRecord>> getAll();

  /// 指定IDの単語レコードを取得する。存在しない場合は `null`。
  Future<WordRecord?> getById(int id);

  /// 単語レコードを登録または更新する。
  Future<void> upsert(WordRecordsCompanion record);

  /// 全単語の重みを初期値（1.0）にリセットする。
  Future<void> resetWeights();

  /// 全単語の学習データを削除する。
  Future<void> deleteAll();
}
