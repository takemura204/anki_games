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
        (session.isAnswered ? AppSpacing.lg : AppSpacing.sm) +
        bottomPadding +
        48.0 +
        sheetExtra;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        headerClearance,
        AppSpacing.md,
        footerClearance,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Gap(AppSpacing.md),

          QuizQuestionCard(question: question, learningLevel: level),
          const Gap(AppSpacing.md),
          ...question.choices.map(
            (choice) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: QuizChoiceButton(
                choice: choice,
                questionNo: question.no,
                correctLabel: question.answer,
                isAnswered: session.isAnswered,
                selectedLabel: session.selectedLabel,
                onTap: () => onAnswer(choice.label),
              ),
            ),
          ),
          GlassContainer(
            cardRadius: AppBorderRadius.md,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: const AdmobBanner(),
          ),
          const Gap(AppSpacing.md),
        ],
      ),
    );
  }
}
