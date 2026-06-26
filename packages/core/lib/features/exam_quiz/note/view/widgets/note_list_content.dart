part of '../note_sheet.dart';

typedef _NoteItemSelectedCallback =
    void Function(
      NoteListItem item, {
      bool fromReview,
      List<NoteListItem>? reviewQueue,
      int reviewIndex,
    });

class _NoteListContent extends ConsumerWidget {
  const _NoteListContent({
    super.key,
    required this.tab,
    required this.asyncState,
    required this.onSelectItem,
  });

  final NoteTab tab;
  final AsyncValue<NoteSheetReady> asyncState;
  final _NoteItemSelectedCallback onSelectItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncState.when(
      loading: () => const _NoteListSkeleton(key: ValueKey('loading')),
      error: (e, _) => Center(
        key: const ValueKey('error'),
        child: Text(
          e.toString(),
          style: AppTextStyle.bodyMedium.copyWith(
            color: context.appColors.fgShade300,
          ),
        ),
      ),
      data: (ready) {
        final items = switch (tab) {
          NoteTab.review => ready.reviewItems,
          NoteTab.bookmark => ready.bookmarkItems,
          NoteTab.history => ready.historyItems,
        };

        if (items.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.separated(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
          itemBuilder: (context, i) => _NoteQuizItemCard(
            item: items[i],
            onTap: () => onSelectItem(
              items[i],
              fromReview: tab == NoteTab.review,
              reviewQueue: items,
              reviewIndex: i,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: context.appColors.fgShade200,
          ),
          const Gap(AppSpacing.sm),
          Text(
            'データがありません',
            style: AppTextStyle.bodyMedium.copyWith(
              color: context.appColors.fgShade300,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteListSkeleton extends StatelessWidget {
  const _NoteListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Shimmer.fromColors(
      baseColor: c.fgShade100,
      highlightColor: c.fgShade50,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: 6,
        separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
        itemBuilder: (_, _) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppBorderRadius.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const Gap(AppSpacing.sm),
          Container(
            width: 36,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Gap(AppSpacing.sm),
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartReviewButton extends StatelessWidget {
  const _StartReviewButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.appColors.surfaceSheet.withValues(alpha: 0),
            context.appColors.surfaceSheet,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: PrimaryButton(
        label: '復習する（$count問）',
        onPressed: onTap,
        icon: Icons.play_arrow_rounded,
      ),
    );
  }
}
