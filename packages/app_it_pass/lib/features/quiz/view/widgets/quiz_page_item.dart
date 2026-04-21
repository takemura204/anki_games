part of '../quiz_screen.dart';

class _QuizPageItem extends ConsumerWidget {
  const _QuizPageItem({
    required this.session,
    required this.onAnswer,
    required this.topPadding,
    required this.bottomPadding,
    this.isSheetOpen = false,
  });

  final QuizSession session;
  final ValueChanged<String> onAnswer;
  final double topPadding;
  final double bottomPadding;

  /// true のとき、シート高さ分の追加パディングを下部に付与する。
  /// コンテンツをスクロールしてシート背後の選択肢を確認できるようにする。
  final bool isSheetOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = session.currentQuestion;
    final statsAsync = ref.watch(itPassLearningStatsProvider);
    final key = LocalLearningHistoryRepository.storageKey(
      question.eraId,
      question.no,
    );
    final level = statsAsync.maybeWhen(
      data: (map) => LearningLevel.fromStats(map[key]),
      orElse: () => LearningLevel.unseen,
    );
    final screenHeight = MediaQuery.of(context).size.height;
    final headerClearance = topPadding + 80.0;
    final sheetExtra = isSheetOpen ? screenHeight * 0.55 : 0.0;
    final footerClearance =
        (session.isAnswered ? 80.0 : 16.0) + bottomPadding + 48.0 + sheetExtra;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, headerClearance, 20, footerClearance),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QuestionCard(question: question, learningLevel: level),
          const Gap(12),
          ...question.choices.map(
            (choice) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChoiceButton(
                choice: choice,
                session: session,
                onTap: () => onAnswer(choice.label),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
