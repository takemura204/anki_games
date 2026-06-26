part of '../note_sheet.dart';

class _NoteQuizItemCard extends ConsumerWidget {
  const _NoteQuizItemCard({required this.item, required this.onTap});

  final NoteListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = item.question;
    final storageKey = LocalLearningHistoryRepository.storageKey(q.eraId, q.no);
    final liveBookmarks = switch (ref.watch(bookmarkProvider)) {
      AsyncData(:final value) => value,
      _ => const <String>{},
    };
    final isBookmarked = liveBookmarks.contains(storageKey);
    final c = context.appColors;

    return GestureDetector(
      onTap: onTap.withHaptic(),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: AppBorderRadius.md,
          border: Border.all(color: c.border1),
        ),
        child: Row(
          children: [
            if (item.lastWasCorrect != null) ...[
              Icon(
                item.lastWasCorrect! ? AppIcons.correct : AppIcons.incorrect,
                size: 16,
                color:
                    item.lastWasCorrect! ? AppColors.success : AppColors.error,
              ),
              const Gap(AppSpacing.xs),
            ],
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${q.no}.',
                    style: AppTextStyle.labelLarge.copyWith(
                      color: c.fg,
                      height: 1.3,
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  Expanded(
                    child: Text(
                      q.title,
                      style: AppTextStyle.labelLarge.copyWith(
                        color: c.fg,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.level.colorBg,
                borderRadius: AppBorderRadius.sm -
                    const BorderRadius.all(Radius.circular(2)),
              ),
              child: Text(
                item.level.label,
                style: AppTextStyle.labelSmall.copyWith(
                  color: item.level.colorFg,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(AppSpacing.sm),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: (() => ref
                      .read(bookmarkProvider.notifier)
                      .toggle(q.eraId, q.no))
                  .withHaptic(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isBookmarked ? AppIcons.bookmarked : AppIcons.bookmark,
                  color: isBookmarked ? ItPassColors.seed : c.fgShade200,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
