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

  /// 学習ステージ（0=未学習〜5=習得済み）。問題形式を決定する。
  IntColumn get stage => integer().withDefault(const Constant(0))();

  /// 連続正解数（正: 連続正解、負: 連続失敗）。ステージ昇降判定に使用。
  IntColumn get consecutiveStreak =>
      integer().withDefault(const Constant(0))();

  /// 次回レビュー予定日時（SRS）。null = 未出題 or 即出題可能。
  DateTimeColumn get nextReviewAt => dateTime().nullable()();

  /// 現在の SRS インターバル（時間単位）。適応型計算に使用。
  RealColumn get intervalHours =>
      real().withDefault(const Constant<double>(4))();

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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement(
              'ALTER TABLE word_records'
              ' ADD COLUMN stage INTEGER NOT NULL DEFAULT 0',
            );
            await customStatement(
              'ALTER TABLE word_records'
              ' ADD COLUMN consecutive_streak INTEGER NOT NULL DEFAULT 0',
            );
            // 既存 weight から stage を推定（学習進捗を引き継ぐ）
            await customStatement('''
              UPDATE word_records
              SET stage = CASE
                WHEN weight < 0.5 THEN 4
                WHEN weight < 2.0 THEN 2
                ELSE 1
              END
            ''');
          }
          if (from < 3) {
            await customStatement(
              'ALTER TABLE word_records'
              ' ADD COLUMN next_review_at INTEGER',
            );
            await customStatement(
              'ALTER TABLE word_records'
              ' ADD COLUMN interval_hours REAL NOT NULL DEFAULT 4.0',
            );
          }
        },
      );

  static QueryExecutor _openConnection() =>
      driftDatabase(name: 'quiz_word_records');
}
