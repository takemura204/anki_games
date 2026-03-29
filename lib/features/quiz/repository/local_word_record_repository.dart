import 'package:drift/drift.dart';
import 'package:mono_games/features/quiz/db/app_database.dart';
import 'package:mono_games/features/quiz/repository/word_record_repository.dart';

/// [WordRecordRepository] の Drift (SQLite) 実装。
class LocalWordRecordRepository implements WordRecordRepository {
  /// [LocalWordRecordRepository] を作成する。
  LocalWordRecordRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<WordRecord>> getAll() => _db.select(_db.wordRecords).get();

  @override
  Future<WordRecord?> getById(int id) {
    final query = _db.select(_db.wordRecords)
      ..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  @override
  Future<void> upsert(WordRecordsCompanion record) =>
      _db.into(_db.wordRecords).insertOnConflictUpdate(record);

  @override
  Future<void> resetWeights() =>
      _db.update(_db.wordRecords).write(
        const WordRecordsCompanion(weight: Value(1)),
      );

  @override
  Future<void> deleteAll() => _db.delete(_db.wordRecords).go();
}
