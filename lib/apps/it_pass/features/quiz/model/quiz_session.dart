import 'package:anki_games/apps/it_pass/features/quiz/model/question.dart';

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
  QuizSession({
    required this.questions,
    this.currentIndex = 0,
    this.selectedLabel,
    this.answerState = AnswerState.unanswered,
    this.showExplanation = false,
    this.showSetResult = false,
    this.currentSetAnswers = const [],
    this.setElapsedAtResult,
    DateTime? setStartTime,
  }) : setStartTime = setStartTime ?? DateTime.now();

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

  /// 現在のセッション内での位置（0 始まり）。1 セッションは最大10問。
  int get indexInSet => currentIndex;

  /// セット内の経過時間（結果表示前）
  Duration get setElapsed => DateTime.now().difference(setStartTime);

  int get setCorrectCount =>
      currentSetAnswers.where((r) => r.isCorrect).length;

  List<QuestionResult> get setWrongAnswers =>
      currentSetAnswers.where((r) => !r.isCorrect).toList();

  QuizSession copyWith({
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
      questions: questions,
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
