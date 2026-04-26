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
    final bookmarks = switch (ref.watch(bookmarkProvider)) {
      AsyncData(:final value) => value,
      _ => const <String>{}
    };

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
                      ModalHandle(),
                      _ExplanationSheetHeader(
                        isBookmarked: bookmarks.contains(
                            '${widget.question.eraId}_${widget.question.no}'),
                        onTapBookmark: () => ref
                            .read(bookmarkProvider.notifier)
                            .toggle(widget.question.eraId, widget.question.no),
                      ),
                      Expanded(
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
                                const Gap(AppSpacing.sm),
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
                                  const Gap(AppSpacing.sm),
                                  ...widget.question.explanationImages
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: AppSpacing.sm,
                                          ),
                                          child: QuizNetworkImage(
                                            url: e.value,
                                            heroTag: 'img_q'
                                                '${widget.question.no}'
                                                '_exp_${e.key}',
                                          ),
                                        ),
                                      ),
                                ],
                                const Gap(AppSpacing.md),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    GestureDetector(
                                      onTap: () => launchUrl(
                                        Uri.parse(AppUrls.contact),
                                        mode: LaunchMode.externalApplication,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            AppIcons.flag,
                                            color: context.appColors.fgShade300,
                                            size: 14,
                                          ),
                                          const Gap(3),
                                          Text(
                                            '誤りを報告',
                                            style: AppTextStyle.labelSmall
                                                .copyWith(
                                              color:
                                                  context.appColors.fgShade300,
                                              letterSpacing: 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Created by Gimini',
                                        style:
                                            AppTextStyle.captionSmall.copyWith(
                                          color: context.appColors.fgShade300,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
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
                        child: _buildNextButton(),
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
                color: valueColor,
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
                widget.isLast ? Icons.flag_rounded : AppIcons.nextUp,
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

class _ExplanationSheetHeader extends StatelessWidget {
  const _ExplanationSheetHeader({
    required this.isBookmarked,
    required this.onTapBookmark,
  });

  final bool isBookmarked;
  final VoidCallback onTapBookmark;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  AppIcons.explanation,
                  color: c.fgShade400,
                ),
                const Gap(AppSpacing.xs),
                Text(
                  '解説',
                  style: AppTextStyle.titleLarge.copyWith(
                    color: c.fgShade400,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.sm),
          GlassButton(
            cardRadius: AppBorderRadius.circle,
            child: IconButton(
              icon: Icon(
                isBookmarked ? AppIcons.bookmarked : AppIcons.bookmark,
                color: isBookmarked
                    ? AppColors.itPassSeed
                    : context.appColors.fgShade300,
              ),
              onPressed: onTapBookmark,
            ),
          ),
          const Gap(AppSpacing.sm),
        ],
      ),
    );
  }
}
