part of '../quiz_screen.dart';

class _Footer extends StatelessWidget {
  const _Footer({
    required this.showActionBar,
    required this.cardRadius,
    required this.session,
    required this.onShowExplanation,
    required this.onNext,
    required this.onUserPressed,
    required this.onFilterPressed,
  });
  final bool showActionBar;
  final BorderRadius cardRadius;
  final QuizSession session;
  final VoidCallback onShowExplanation;
  final VoidCallback onNext;

  final VoidCallback onUserPressed;
  final VoidCallback onFilterPressed;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 4,
        bottom: bottom + 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassButton(
            cardRadius: cardRadius,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.grid_view_outlined,
                color: Colors.white70,
                size: 22,
              ),
              onPressed: onUserPressed,
            ),
          ),
          const Gap(15),
          Expanded(
            child: IgnorePointer(
              ignoring: !showActionBar,
              child: AnimatedSlide(
                offset: showActionBar ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: showActionBar ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _AnsweredActionBar(
                    onShowExplanation: onShowExplanation,
                    onNext: onNext,
                  ),
                ),
              ),
            ),
          ),
          const Gap(15),
          _GlassButton(
            cardRadius: cardRadius,
            child: IconButton(
              iconSize: 22,
              padding: EdgeInsets.zero,
              color: Colors.white70,
              icon: const Icon(Icons.insert_chart_outlined),
              onPressed: onFilterPressed,
            ),
          ),
        ],
      ),
    );
  }
}
