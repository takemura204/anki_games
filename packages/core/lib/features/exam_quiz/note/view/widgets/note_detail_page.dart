part of '../note_sheet.dart';

class _NoteDetailPage extends ConsumerStatefulWidget {
  const _NoteDetailPage({
    required this.args,
    required this.onReviewAnswered,
    required this.onPageChanged,
  });

  final _DetailPageArgs args;
  final VoidCallback onReviewAnswered;
  final void Function(int index) onPageChanged;

  @override
  ConsumerState<_NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<_NoteDetailPage> {
  late final PageController _pageController;
  late int _currentIndex;

  _DetailPageArgs get _args => widget.args;

  @override
  void initState() {
    super.initState();
    _currentIndex = _args.initialIndex;
    _pageController = PageController(initialPage: _args.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleReviewAction({required bool isCorrect}) {
    final q = _args.reviewQueue[_currentIndex].question;
    final repo = ref.read(learningHistoryRepositoryProvider).asData?.value;
    repo
        ?.recordAnswer(
          eraId: q.eraId,
          no: q.no,
          isCorrect: isCorrect,
          at: DateTime.now(),
          selectedLabel: isCorrect ? q.answer : '',
        )
        .then((_) => widget.onReviewAnswered());

    final isLast = _currentIndex >= _args.reviewQueue.length - 1;
    if (isLast) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextItem() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPrevItem() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Gap(AppSpacing.sm),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: _args.fromReview
                ? const NeverScrollableScrollPhysics()
                : const ClampingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
              widget.onPageChanged(index);
            },
            itemCount: _args.reviewQueue.length,
            itemBuilder: (context, index) => _NoteDetailView(
              key: ValueKey('detail_$index'),
              item: _args.reviewQueue[index],
              fromReview: _args.fromReview,
              onKnown: _args.fromReview
                  ? () => _handleReviewAction(isCorrect: true)
                  : null,
              onUnsure: _args.fromReview
                  ? () => _handleReviewAction(isCorrect: false)
                  : null,
            ),
          ),
        ),
        if (!_args.fromReview)
          _BrowseActionButtons(
            canGoPrev: _currentIndex > 0,
            canGoNext: _currentIndex < _args.reviewQueue.length - 1,
            onPrev: _goToPrevItem,
            onNext: _goToNextItem,
          ),
      ],
    );
  }
}
