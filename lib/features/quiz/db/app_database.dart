import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// 単語学習履歴テーブル。
class WordRecords extends Table {
  /// 単語ID（CSVのidと対応）。
  IntColumn get id => integer()();

  /// 正解回数。
  IntColumn get correctCount => integer().withDefault(const Constant(0))();

  /// 不正解回数。
  IntColumn get incorrectCount => integer().withDefault(const Constant(0))();

  /// 出題重み（初期値 1.0、正解で減少・不正解で増加）。
  RealColumn get weight => real().withDefault(const Constant<double>(1))();

  /// 最終出題日時。
  DateTimeColumn get lastSeenAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// クイズ学習データの SQLite データベース。
///
/// Drift ORM を使用。将来 Firestore へ移行する場合は
/// WordRecordRepository の実装を差し替えるだけで対応可能。
@DriftDatabase(tables: [WordRecords])
class AppDatabase extends _$AppDatabase {
  /// [AppDatabase] を作成する。
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() =>
      driftDatabase(name: 'quiz_word_records');
}
