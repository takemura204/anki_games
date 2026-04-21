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

    /// 品詞（noun / verb / adjective / adverb / preposition / conjunction / phrase）。
    required String pos,

    /// テーマ（nature / daily / people / place / action / mind / general）。
    required String theme,

    /// 資格レベル（eiken5, eiken4, eiken3, eiken2pre, eiken2, toeic_basic, general）。
    @Default('general') String level,

    /// 頻出単語フラグ（頻出50選に含まれる場合 true）。
    @Default(false) bool isFrequent,
  }) = _QuizWord;
}
