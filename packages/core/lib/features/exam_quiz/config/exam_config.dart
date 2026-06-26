import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../model/exam_meta.dart';

/// 試験の種類・データ定義を注入する抽象設定。
///
/// 各アプリの `main.dart` で [examConfigProvider] をオーバーライドして使う:
/// ```dart
/// examConfigProvider.overrideWithValue(ItPassExamConfig())
/// ```
abstract class ExamConfig {
  const ExamConfig();
  List<ExamMeta> get examList;

  /// カテゴリツリー: { '大分類': ['小分類', ...] }
  Map<String, List<String>> get categoryTree;

  /// リリース環境でフリー公開する試験回の eraId セット。
  Set<String> get freeEraIds;

  /// 試験の識別子（例: 'it_pass', 'fe', 'fp3'）。
  String get examTypeKey;

  /// リリースビルドではサンプル問題を除外した試験一覧。
  List<ExamMeta> get availableExamList =>
      examList.where((m) => !m.isSample).toList();
}

/// 試験設定プロバイダー。各アプリの `main.dart` で必ずオーバーライドする。
final examConfigProvider = Provider<ExamConfig>(
  (ref) => throw UnimplementedError('examConfigProvider must be overridden'),
  name: 'examConfigProvider',
);
