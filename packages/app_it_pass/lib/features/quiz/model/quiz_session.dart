import 'question.dart';

enum AnswerState { unanswered, correct, incorrect }

class QuestionResult {
  const QuestionResult({
    required this.question,
    required this.isCorrect,
    required this.selectedLabel,
  });

  final Question question;
  final bool isCorrect;
  final String selectedLabel;
}

class QuizSession {
  /// 1セット当たりの最大出題数。
  static const setSize = 10;

  QuizSession({
    required this.allQuestions,
    this.currentSetIndex = 0,
    this.currentIndex = 0,
    this.selectedLabel,
    this.answerState = AnswerState.unanswered,
    this.showExplanation = false,
    this.showSetResult = false,
    this.currentSetAnswers = const [],
    this.setElapsedAtResult,
    DateTime? setStartTime,
  })  : questions = allQuestions.sublist(
          currentSetIndex * setSize,
          ((currentSetIndex + 1) * setSize).clamp(0, allQuestions.length),
        ),
        setStartTime = setStartTime ?? DateTime.now();

  /// フィルター後の全問題リスト（順序済み）。
  final List<Question> allQuestions;

  /// 現在表示しているセットのインデックス（0始まり）。
  final int currentSetIndex;

  /// 現在のセット内の問題リスト（最大 [setSize] 件）。
  final List<Question> questions;

  final int currentIndex;
  final String? selectedLabel;
  final AnswerState answerState;
  final bool showExplanation;
  final bool showSetResult;
  final List<QuestionResult> currentSetAnswers;
  final Duration? setElapsedAtResult;
  final DateTime setStartTime;

  Question get currentQuestion => questions[currentIndex];
  int get totalCount => questions.length;
  bool get isAnswered => answerState != AnswerState.unanswered;

  /// 現在のセッション内での位置（0始まり）。
  int get indexInSet => currentIndex;

  /// セット内の経過時間（結果表示前）。
  Duration get setElapsed => DateTime.now().difference(setStartTime);

  int get setCorrectCount => currentSetAnswers.where((r) => r.isCorrect).length;

  List<QuestionResult> get setWrongAnswers =>
      currentSetAnswers.where((r) => !r.isCorrect).toList();

  /// 次のセットが存在するかどうか。
  bool get hasNextSet =>
      (currentSetIndex + 1) * setSize < allQuestions.length;

  /// 全セット数（切り上げ）。
  int get totalSets => (allQuestions.length / setSize).ceil();

  QuizSession copyWith({
    int? currentSetIndex,
    int? currentIndex,
    String? selectedLabel,
    AnswerState? answerState,
    bool? showExplanation,
    bool? showSetResult,
    List<QuestionResult>? currentSetAnswers,
    Duration? setElapsedAtResult,
    DateTime? setStartTime,
  }) {
    return QuizSession(
      allQuestions: allQuestions,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedLabel: selectedLabel ?? this.selectedLabel,
      answerState: answerState ?? this.answerState,
      showExplanation: showExplanation ?? this.showExplanation,
      showSetResult: showSetResult ?? this.showSetResult,
      currentSetAnswers: currentSetAnswers ?? this.currentSetAnswers,
      setElapsedAtResult: setElapsedAtResult ?? this.setElapsedAtResult,
      setStartTime: setStartTime ?? this.setStartTime,
    );
  }
}
