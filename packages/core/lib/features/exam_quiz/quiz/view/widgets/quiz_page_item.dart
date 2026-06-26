part of '../quiz_screen.dart';

class _QuizPageItem extends ConsumerStatefulWidget {
  const _QuizPageItem({
    required this.session,
    required this.onAnswer,
    required this.topPadding,
    required this.bottomPadding,
  });

  final QuizSession session;
  final ValueChanged<String> onAnswer;
  final double topPadding;
  final double bottomPadding;

  @override
  ConsumerState<_QuizPageItem> createState() => _QuizPageItemState();
}

class _QuizPageItemState extends ConsumerState<_QuizPageItem> {
  final _scrollController = ScrollController();

  /// 解説カードが展開される直前の位置マーカー。
  /// AnimatedSize の外（上側）に置くことでカード展開中も位置が安定する。
  final GlobalKey<State<StatefulWidget>> _scrollAnchorKey = GlobalKey();

  /// 正解時に「解説を見る」を押した後 true になる。
  bool _explanationExpanded = false;

  @override
  void didUpdateWidget(_QuizPageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.session.isAnswered && widget.session.isAnswered) {
      // 不正解時のみ自動スクロール
      if (widget.session.answerState == AnswerState.incorrect) {
        Future.delayed(const Duration(milliseconds: 150), _scrollToExplanation);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _expandExplanation() {
    setState(() => _explanationExpanded = true);
    Future.delayed(const Duration(milliseconds: 50), _scrollToExplanation);
  }

  void _scrollToExplanation() {
    if (!mounted || !_scrollController.hasClients) return;
    final anchorContext = _scrollAnchorKey.currentContext;
    if (anchorContext == null) return;
    final anchorBox = anchorContext.findRenderObject() as RenderBox?;
    if (anchorBox == null) return;

    // 解説カードアンカーのグローバル Y 座標を取得
    final anchorGlobalY = anchorBox.localToGlobal(Offset.zero).dy;
    final screenHeight = MediaQuery.of(context).size.height;

    // アンカー（解説カード上端）を画面の約45%の位置に配置する
    final targetOffset =
        _scrollController.offset + anchorGlobalY - screenHeight * 0.6;

    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
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
    final bookmarks = switch (ref.watch(bookmarkProvider)) {
      AsyncData(:final value) => value,
      _ => const <String>{},
    };
    final bookmarkKey = LocalLearningHistoryRepository.storageKey(
      question.eraId,
      question.no,
    );
    final isBookmarked = bookmarks.contains(bookmarkKey);

    final headerClearance = widget.topPadding + 80.0;
    final footerClearance = widget.bottomPadding + 48.0 + AppSpacing.sm;

    return SingleChildScrollView(
      controller: _scrollController,
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
          QuizQuestionCard(
            question: question,
            learningLevel: level,
            isBookmarked: isBookmarked,
            onBookmark: () => ref
                .read(bookmarkProvider.notifier)
                .toggle(question.eraId, question.no),
          ),
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
                onTap: () => widget.onAnswer(choice.label),
              ),
            ),
          ),
          // 回答前: Banner / 回答後: Banner を消して解説カード + Native を表示
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: session.isAnswered
                ? const SizedBox.shrink()
                : const AdmobBannerGlass(),
          ),
          // 解説カードのスクロール位置アンカー（常に DOM に存在）
          SizedBox(key: _scrollAnchorKey, height: 0),
          AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: session.isAnswered && session.selectedLabel != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Gap(AppSpacing.md),
                      if (session.answerState == AnswerState.correct &&
                          !_explanationExpanded)
                        CollapsedExplanationCard(onExpand: _expandExplanation)
                      else ...[
                        ExplanationCard(
                          question: question,
                          selectedLabel: session.selectedLabel!,
                          showExtras: true,
                        ),
                        const Gap(AppSpacing.md),
                        const AdmobNativeGlass(),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const Gap(AppSpacing.md),
        ],
      ),
    );
  }
}
