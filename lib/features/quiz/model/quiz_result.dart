import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mono_games/features/quiz/model/quiz_word.dart';

part 'quiz_result.freezed.dart';

/// 1問の回答結果。
@freezed
abstract class QuizAnswerResult with _$QuizAnswerResult {
  /// [QuizAnswerResult] を作成する。
  const factory QuizAnswerResult({
    /// 出題された単語。
    required QuizWord word,

    /// 正解したかどうか。
    required bool isCorrect,

    /// 正解の訳文（常に表示用）。
    required String correctAnswer,

    /// 期限超過単語を正解した場合のボーナス得点（0 = ボーナスなし）。
    @Default(0) int overdueBonus,
  }) = _QuizAnswerResult;
}

/// 3問分のクイズラウンド結果。
@freezed
abstract class QuizResult with _$QuizResult {
  /// [QuizResult] を作成する。
  const factory QuizResult({
    /// 3問分の回答結果リスト。
    required List<QuizAnswerResult> answers,
  }) = _QuizResult;
}

/// [QuizResult] の拡張メソッド。
extension QuizResultX on QuizResult {
  /// 正解数（0〜3）。
  int get correctCount => answers.where((a) => a.isCorrect).length;
}
