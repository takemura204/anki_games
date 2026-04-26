part of '../note_sheet.dart';

class _NoteDetailView extends StatelessWidget {
  const _NoteDetailView({
    super.key,
    required this.item,
    this.fromReview = false,
    this.onKnown,
    this.onUnsure,
  });

  final NoteListItem item;
  final bool fromReview;
  final VoidCallback? onKnown;
  final VoidCallback? onUnsure;

  @override
  Widget build(BuildContext context) {
    final q = item.question;
    final c = context.appColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuizQuestionCard(
              question: q,
              learningLevel: item.level,
            ),
            const Gap(12),
            ...q.choices.map(
              (choice) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: QuizChoiceButton(
                  choice: choice,
                  questionNo: q.no,
                  correctLabel: q.answer,
                  isAnswered: true,
                  selectedLabel: item.selectedLabel,
                ),
              ),
            ),
            const Gap(AppSpacing.sm),
            if (q.explanationText.isNotEmpty)
              _ExplanationSection(
                explanationText: q.explanationText,
                choiceComments: q.explanationChoiceComments,
                colors: c,
              ),
            if (fromReview) ...[
              const Gap(AppSpacing.sm),
              Divider(height: AppSpacing.lg, color: c.border1),
              _ReviewActionButtons(
                onKnown: onKnown,
                onUnsure: onUnsure,
              ),
            ],
            Gap(AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ExplanationSection extends StatelessWidget {
  const _ExplanationSection({
    required this.explanationText,
    required this.choiceComments,
    required this.colors,
  });

  final String explanationText;
  final List<String> choiceComments;
  final ItPassColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: AppSpacing.lg, color: colors.border1),
        Row(
          children: [
            Icon(AppIcons.explanation, color: colors.fg, size: 16),
            const Gap(6),
            Text(
              '解説',
              style: AppTextStyle.titleSmall.copyWith(color: colors.fg),
            ),
          ],
        ),
        const Gap(AppSpacing.sm),
        Text(
          explanationText,
          style: AppTextStyle.bodySmall.copyWith(
            color: colors.fg,
            height: 1.75,
          ),
        ),
        if (choiceComments.isNotEmpty) ...[
          const Gap(AppSpacing.md),
          _ChoiceCommentsSection(comments: choiceComments, colors: colors),
        ],
        const Gap(AppSpacing.md),
        _ReferenceSection(),
      ],
    );
  }
}

class _ChoiceCommentsSection extends StatelessWidget {
  const _ChoiceCommentsSection({
    required this.comments,
    required this.colors,
  });

  final List<String> comments;
  final ItPassColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: AppBorderRadius.sm,
      ),
      child: Column(
        children: comments.asMap().entries.map((e) {
          if (e.value.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${String.fromCharCode(97 + e.key)}. ',
                  style: AppTextStyle.bodySmall.copyWith(color: colors.fg),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: colors.fg,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReferenceSection extends StatelessWidget {
  const _ReferenceSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                style: AppTextStyle.labelSmall.copyWith(
                  color: context.appColors.fgShade300,
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
            style: AppTextStyle.captionSmall.copyWith(
              color: context.appColors.fgShade300,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrowseActionButtons extends StatelessWidget {
  const _BrowseActionButtons({
    required this.canGoPrev,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  final bool canGoPrev;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              border: Border.all(color: c.border1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: canGoPrev ? onPrev : null,
                    icon: Icon(
                      AppIcons.prevLeft,
                      color: canGoPrev ? c.fg : c.fgShade200,
                      size: 16,
                    ),
                    label: Text(
                      '前の問題へ',
                      style: AppTextStyle.titleSmall.copyWith(
                        color: canGoPrev ? c.fg : c.fgShade200,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 28, color: c.fgShade50),
                Expanded(
                  child: TextButton.icon(
                    onPressed: canGoNext ? onNext : null,
                    iconAlignment: IconAlignment.end,
                    icon: Icon(
                      AppIcons.nextRight,
                      color: canGoNext ? c.fg : c.fgShade200,
                      size: 20,
                    ),
                    label: Text(
                      '次の問題へ',
                      style: AppTextStyle.titleSmall.copyWith(
                        color: canGoNext ? c.fg : c.fgShade200,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewActionButtons extends StatelessWidget {
  const _ReviewActionButtons({this.onKnown, this.onUnsure});

  final VoidCallback? onKnown;
  final VoidCallback? onUnsure;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onUnsure,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: AppBorderRadius.lg,
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.replay_rounded,
                      color: AppColors.error, size: 20),
                  const Gap(AppSpacing.sm),
                  Text(
                    'もう一度',
                    style: AppTextStyle.titleSmall
                        .copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: onKnown,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: AppBorderRadius.lg,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(AppIcons.review, color: Colors.white, size: 20),
                  const Gap(AppSpacing.sm),
                  Text(
                    '覚えた',
                    style:
                        AppTextStyle.titleSmall.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
