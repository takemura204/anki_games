part of '../note_sheet.dart';

class _NoteDetailPage extends ConsumerStatefulWidget {
  const _NoteDetailPage({
    required this.args,
    required this.onMarkMastered,
    required this.onPageChanged,
  });

  final _DetailPageArgs args;
  final VoidCallback onMarkMastered;
  final void Function(int index, int masteredCount) onPageChanged;

  @override
  ConsumerState<_NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends ConsumerState<_NoteDetailPage> {
  late final PageController _pageController;
  late int _currentIndex;
  int _masteredCount = 0;

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

  void _goToNextReviewItem({required bool known}) {
    if (known) {
      final q = _args.reviewQueue[_currentIndex].question;
      LocalLearningHistoryRepository().markMastered(q.eraId, q.no).then((_) {
        widget.onMarkMastered();
      });
    }

    final isLast = _currentIndex >= _args.reviewQueue.length - 1;
    if (isLast) {
      if (known) {
        setState(() => _masteredCount = _args.reviewQueue.length);
        widget.onPageChanged(_currentIndex, _args.reviewQueue.length);
      }
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (known) {
      setState(() => _masteredCount++);
      widget.onPageChanged(_currentIndex, _masteredCount);
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
              widget.onPageChanged(index, _masteredCount);
            },
            itemCount: _args.reviewQueue.length,
            itemBuilder: (context, index) => _NoteDetailView(
              key: ValueKey('detail_$index'),
              item: _args.reviewQueue[index],
              fromReview: _args.fromReview,
              onKnown: _args.fromReview
                  ? () => _goToNextReviewItem(known: true)
                  : null,
              onUnsure: _args.fromReview
                  ? () => _goToNextReviewItem(known: false)
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
