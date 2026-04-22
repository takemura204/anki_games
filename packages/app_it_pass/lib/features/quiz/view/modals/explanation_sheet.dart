part of '../quiz_screen.dart';

class _ExplanationSheet extends ConsumerStatefulWidget {
  const _ExplanationSheet({
    required this.sheetController,
    required this.slideAnimation,
    required this.question,
    required this.selectedLabel,
    required this.isLast,
    required this.onNext,
    required this.onDismiss,
  });

  final AnimationController sheetController;
  final Animation<Offset> slideAnimation;
  final Question question;
  final String selectedLabel;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onDismiss;

  @override
  ConsumerState<_ExplanationSheet> createState() => _ExplanationSheetState();
}

class _ExplanationSheetState extends ConsumerState<_ExplanationSheet> {
  var _dragStartY = 0.0;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final dy = details.globalPosition.dy - _dragStartY;
    if (dy > 0) {
      final sheetHeight = MediaQuery.of(context).size.height * 0.65;
      final normalized = 1.0 - (dy / sheetHeight).clamp(0.0, 1.0);
      widget.sheetController.value = normalized;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -500) {
      widget.onNext();
    } else if (velocity > 400 || widget.sheetController.value < 0.5) {
      widget.onDismiss();
    } else {
      widget.sheetController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final c = context.appColors;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SlideTransition(
        position: widget.slideAnimation,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: SafeArea(
            top: false,
            bottom: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.55),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: context.appColors.bgGradient,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDragHandle(),
                      Flexible(
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.sm,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                const Gap(12),
                                Row(
                                  children: [
                                    _buildAnswerChip(
                                      label: '正解',
                                      value: widget.question.answer,
                                      valueColor: AppColors.success,
                                    ),
                                    const Gap(12),
                                    _buildAnswerChip(
                                      label: 'あなた',
                                      value: widget.selectedLabel,
                                      valueColor: widget.selectedLabel ==
                                              widget.question.answer
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ],
                                ),
                                const Gap(AppSpacing.sm),
                                if (widget.question.explanationChoiceComments
                                    .isNotEmpty) ...[
                                  const Gap(AppSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: c.surface2,
                                      borderRadius: AppBorderRadius.sm,
                                    ),
                                    child: Column(children: [
                                      ...widget
                                          .question.explanationChoiceComments
                                          .asMap()
                                          .entries
                                          .map(
                                            (e) => Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: AppSpacing.xs + 2,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${String.fromCharCode(97 + e.key)}. ',
                                                    style: AppTextStyle
                                                        .bodySmall
                                                        .copyWith(color: c.fg),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      e.value,
                                                      style: AppTextStyle
                                                          .bodySmall
                                                          .copyWith(
                                                        color: c.fg,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                    ]),
                                  ),
                                ],
                                const Gap(AppSpacing.sm),
                                Text(
                                  widget.question.explanationText,
                                  style: AppTextStyle.bodySmall.copyWith(
                                    color: context.appColors.fg,
                                    height: 1.75,
                                  ),
                                ),
                                if (widget
                                    .question.explanationImages.isNotEmpty) ...[
                                  const Gap(12),
                                  ...widget.question.explanationImages
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: AppSpacing.sm,
                                          ),
                                          child: _QuizNetworkImage(
                                            url: e.value,
                                            heroTag: 'img_q'
                                                '${widget.question.no}'
                                                '_exp_${e.key}',
                                          ),
                                        ),
                                      ),
                                ],
                                const Gap(15),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Created by Gimini',
                                    style: AppTextStyle.captionSmall.copyWith(
                                      color: context.appColors.fgShade200,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        child: _buildBottomActions(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.appColors.fgShade100,
            borderRadius:
                AppBorderRadius.sm - const BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.lightbulb_outline_rounded,
          color: context.appColors.fg,
          size: 18,
        ),
        const Gap(AppSpacing.sm),
        Text(
          '解説',
          style: AppTextStyle.titleSmall.copyWith(
            color: context.appColors.fg,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => launchUrl(
            Uri.parse(AppUrls.contact),
            mode: LaunchMode.externalApplication,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag_outlined,
                color: context.appColors.fgShade300,
                size: 14,
              ),
              const Gap(3),
              Text(
                '誤りを報告',
                style: AppTextStyle.labelSmall.copyWith(
                  color: context.appColors.fgShade300,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerChip({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: valueColor.withValues(alpha: 0.10),
        borderRadius: AppBorderRadius.sm,
        border: Border.all(color: valueColor.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: AppTextStyle.labelLarge.copyWith(
                color: context.appColors.fgShade400,
                fontWeight: FontWeight.normal,
                letterSpacing: 0,
              ),
            ),
            Text(
              value,
              style: AppTextStyle.titleSmall.copyWith(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    final q = widget.question;
    final bookmarks = switch (ref.watch(bookmarkProvider)) {
      AsyncData(:final value) => value,
      _ => const <String>{},
    };
    final key = '${q.eraId}_${q.no}';
    final isBookmarked = bookmarks.contains(key);

    return Row(
      children: [
        GlassButton(
          cardRadius: AppBorderRadius.md,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isBookmarked
                  ? AppColors.itPassSeed
                  : context.appColors.fgShade300,
              size: 22,
            ),
            onPressed: () =>
                ref.read(bookmarkProvider.notifier).toggle(q.eraId, q.no),
          ),
        ),
        const Gap(AppSpacing.sm),
        Expanded(child: _buildNextButton()),
      ],
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: widget.onNext,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.itPassSeed, AppColors.itPassAccent],
          ),
          borderRadius: AppBorderRadius.md,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isLast ? '結果を見る' : '次の問題へ',
                style: AppTextStyle.titleMedium.copyWith(
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const Gap(AppSpacing.sm),
              Icon(
                widget.isLast
                    ? Icons.flag_rounded
                    : Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: AppSpacing.md + 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
