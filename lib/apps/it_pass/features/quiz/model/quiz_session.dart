import 'package:anki_games/apps/it_pass/features/quiz/model/question.dart';

enum AnswerState { unanswered, correct, incorrect }

class QuizSession {
  const QuizSession({
    required this.questions,
    this.currentIndex = 0,
    this.selectedLabel,
    this.answerState = AnswerState.unanswered,
    this.showExplanation = false,
    this.isFinished = false,
  });

  final List<Question> questions;
  final int currentIndex;
  final String? selectedLabel;
  final AnswerState answerState;
  final bool showExplanation;
  final bool isFinished;

  Question get currentQuestion => questions[currentIndex];
  int get totalCount => questions.length;
  int get correctCount => 0; // 簡易版: セッション終了時に集計
  bool get isAnswered => answerState != AnswerState.unanswered;

  QuizSession copyWith({
    int? currentIndex,
    String? selectedLabel,
    AnswerState? answerState,
    bool? showExplanation,
    bool? isFinished,
  }) {
    return QuizSession(
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedLabel: selectedLabel ?? this.selectedLabel,
      answerState: answerState ?? this.answerState,
      showExplanation: showExplanation ?? this.showExplanation,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}
