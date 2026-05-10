part of '../quiz_screen.dart';

class _Footer extends StatelessWidget {
  const _Footer({
    required this.showActionBar,
    required this.cardRadius,
    required this.session,
    required this.onShowExplanation,
    required this.onNext,
    required this.onTapNote,
    required this.onTapReport,
  });
  final bool showActionBar;
  final BorderRadius cardRadius;
  final QuizSession? session;
  final VoidCallback onShowExplanation;
  final VoidCallback onNext;

  final VoidCallback onTapNote;
  final VoidCallback onTapReport;

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
          GlassButton(
            cardRadius: cardRadius,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                AppIcons.note,
                color: context.appColors.fgShade400,
                size: 22,
              ),
              onPressed: onTapNote.withHaptic(),
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
          GlassButton(
            cardRadius: cardRadius,
            child: IconButton(
              iconSize: 22,
              padding: EdgeInsets.zero,
              color: context.appColors.fgShade400,
              icon: const Icon(AppIcons.report),
              onPressed: onTapReport.withHaptic(),
            ),
          ),
        ],
      ),
    );
  }
}
