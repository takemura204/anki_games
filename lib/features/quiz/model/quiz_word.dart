import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_word.freezed.dart';

/// クイズに使用する英単語データ。
@freezed
abstract class QuizWord with _$QuizWord {
  /// [QuizWord] を作成する。
  const factory QuizWord({
    /// CSVのID（DBキーと対応）。
    required int id,

    /// 英単語。
    required String en,

    /// 日本語訳。
    required String ja,

    /// カテゴリ（fruit, verb, adjective, noun, animal, color, body, food）。
    required String category,
  }) = _QuizWord;
}
