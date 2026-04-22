import 'dart:ui';

import 'package:app_it_pass/components/modal_handle.dart';
import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../learning/model/learning_level.dart';
import '../../learning/repository/local_learning_history_repository.dart';
import '../../quiz/model/quiz_session.dart';
import '../model/note_list_item.dart';
import '../providers/bookmark_provider.dart';
import '../view_model/note_sheet_view_model.dart';

class NoteSheet extends ConsumerStatefulWidget {
  const NoteSheet({super.key, required this.session});

  final QuizSession session;

  @override
  ConsumerState<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends ConsumerState<NoteSheet> {
  NoteTab _tab = NoteTab.bookmark;
  NoteListItem? _selectedItem;
  bool _showDetail = false;

  void _selectItem(NoteListItem item) {
    setState(() {
      _selectedItem = item;
      _showDetail = true;
    });
  }

  void _goBack() => setState(() => _showDetail = false);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final asyncState = ref.watch(noteSheetViewModelProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: screenHeight * 0.9,
          decoration: BoxDecoration(
            color: context.appColors.surfaceSheet,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: context.appColors.border1),
            ),
          ),
          child: Column(
            children: [
              const ModalHandle(),
              _buildHeader(),
              if (!_showDetail) _buildTabBar(asyncState),
              Divider(height: 1, color: context.appColors.border1),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: _showDetail && _selectedItem != null
                      ? _NoteDetailView(
                          key: const ValueKey('detail'),
                          item: _selectedItem!,
                        )
                      : _buildListContent(
                          key: ValueKey('list_${_tab.name}'),
                          asyncState: asyncState,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 4, AppSpacing.md, 4),
      child: Row(
        children: [
          if (_showDetail)
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: context.appColors.fgShade400,
              ),
              onPressed: _goBack,
            )
          else
            const SizedBox(width: 44),
          Expanded(
            child: Text(
              '復習ノート',
              style: AppTextStyle.titleMedium
                  .copyWith(color: context.appColors.fg),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildTabBar(AsyncValue<NoteSheetReady> asyncState) {
    final counts = switch (asyncState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _TabPill(
            label: '復習',
            count: counts?.reviewItems.length,
            selected: _tab == NoteTab.review,
            onTap: () => setState(() => _tab = NoteTab.review),
          ),
          const Gap(AppSpacing.sm),
          _TabPill(
            label: 'ブックマーク',
            count: counts?.bookmarkItems.length,
            selected: _tab == NoteTab.bookmark,
            onTap: () => setState(() => _tab = NoteTab.bookmark),
          ),
          const Gap(AppSpacing.sm),
          _TabPill(
            label: '履歴',
            count: widget.session.currentSetAnswers.length,
            selected: _tab == NoteTab.history,
            onTap: () => setState(() => _tab = NoteTab.history),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent({
    Key? key,
    required AsyncValue<NoteSheetReady> asyncState,
  }) {
    if (_tab == NoteTab.history) {
      return _buildHistoryList(key: key, asyncState: asyncState);
    }

    return asyncState.when(
      loading: () => const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: Colors.white54),
      ),
      error: (e, _) => Center(
        key: ValueKey('error'),
        child: Text(
          e.toString(),
          style: AppTextStyle.bodyMedium
              .copyWith(color: context.appColors.fgShade300),
        ),
      ),
      data: (ready) {
        final items =
            _tab == NoteTab.review ? ready.reviewItems : ready.bookmarkItems;
        if (items.isEmpty) {
          return _buildEmptyState(key: key);
        }
        return ListView.separated(
          key: key,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Gap(AppSpacing.sm),
          itemBuilder: (context, i) => _NoteListItemCard(
            item: items[i],
            onTap: () => _selectItem(items[i]),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList({
    Key? key,
    required AsyncValue<NoteSheetReady> asyncState,
  }) {
    final results = widget.session.currentSetAnswers;
    if (results.isEmpty) {
      return _buildEmptyState(key: key);
    }

    final ready = switch (asyncState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final stats = ready?.stats ?? {};
    final initialBookmarks = ready?.bookmarks ?? {};
    final liveBookmarks = switch (ref.watch(bookmarkProvider)) {
      AsyncData(:final value) => value,
      _ => initialBookmarks,
    };

    return ListView.separated(
      key: key,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Gap(AppSpacing.sm),
      itemBuilder: (context, i) {
        final r = results[results.length - 1 - i];
        final storageKey = LocalLearningHistoryRepository.storageKey(
          r.question.eraId,
          r.question.no,
        );
        final item = NoteListItem(
          question: r.question,
          level: LearningLevel.fromStats(stats[storageKey]),
          isBookmarked: liveBookmarks.contains(storageKey),
          selectedLabel: r.selectedLabel,
          lastWasCorrect: r.isCorrect,
        );
        return _NoteListItemCard(
          item: item,
          onTap: () => _selectItem(item),
        );
      },
    );
  }

  Widget _buildEmptyState({Key? key}) {
    return Center(
      key: key,
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
            style: AppTextStyle.bodyMedium
                .copyWith(color: context.appColors.fgShade300),
          ),
        ],
      ),
    );
  }
}

// ─── タブピルボタン ──────────────────────────────────────────────

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final displayLabel = count != null ? '$label $count' : label;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.itPassSeed : c.surface2,
          borderRadius: AppBorderRadius.full,
          border: Border.all(
            color: selected ? AppColors.itPassSeed : c.border1,
          ),
        ),
        child: Text(
          displayLabel,
          style: AppTextStyle.labelMedium.copyWith(
            color: selected ? Colors.white : c.fgShade300,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── リストアイテムカード ────────────────────────────────────────

class _NoteListItemCard extends ConsumerWidget {
  const _NoteListItemCard({required this.item, required this.onTap});

  final NoteListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = item.question;
    final storageKey =
        LocalLearningHistoryRepository.storageKey(q.eraId, q.no);
    final liveBookmarks = switch (ref.watch(bookmarkProvider)) {
      AsyncData(:final value) => value,
      _ => const <String>{},
    };
    final isBookmarked = liveBookmarks.contains(storageKey);
    final c = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: AppBorderRadius.md,
          border: Border.all(color: c.border1),
        ),
        child: Row(
          children: [
            // 学習レベルバッジ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.level.filterBackground,
                borderRadius: AppBorderRadius.sm -
                    const BorderRadius.all(Radius.circular(2)),
              ),
              child: Text(
                item.level.label,
                style: AppTextStyle.labelSmall.copyWith(
                  color: item.level.filterForeground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Gap(AppSpacing.sm),

            // タイトル + 正誤バッジ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q${q.no}. ${q.title}',
                    style: AppTextStyle.labelLarge.copyWith(
                      color: c.fgShade400,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.selectedLabel != null &&
                      item.lastWasCorrect != null) ...[
                    const Gap(3),
                    Row(
                      children: [
                        _SmallBadge(
                          label: 'あなた: ${item.selectedLabel}',
                          color: item.lastWasCorrect!
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const Gap(5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 11,
                          color: c.fgShade100,
                        ),
                        const Gap(5),
                        _SmallBadge(
                          label: '正解: ${q.answer}',
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Gap(AppSpacing.sm),

            // ブックマークボタン
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  ref.read(bookmarkProvider.notifier).toggle(q.eraId, q.no),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isBookmarked ? AppColors.itPassSeed : c.fgShade200,
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

// ─── 詳細ビュー ─────────────────────────────────────────────────

class _NoteDetailView extends ConsumerWidget {
  const _NoteDetailView({super.key, required this.item});

  final NoteListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = item.question;
    final storageKey =
        LocalLearningHistoryRepository.storageKey(q.eraId, q.no);
    final liveBookmarks = switch (ref.watch(bookmarkProvider)) {
      AsyncData(:final value) => value,
      _ => const <String>{},
    };
    final isBookmarked = liveBookmarks.contains(storageKey);
    final c = context.appColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトル行: レベルバッジ + タイトル + ブックマーク
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.level.filterBackground,
                  borderRadius: AppBorderRadius.sm -
                      const BorderRadius.all(Radius.circular(2)),
                ),
                child: Text(
                  item.level.label,
                  style: AppTextStyle.labelSmall.copyWith(
                    color: item.level.filterForeground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: Text(
                  'Q${q.no}. ${q.title}',
                  style: AppTextStyle.titleSmall.copyWith(
                    color: c.fg,
                    height: 1.4,
                  ),
                ),
              ),
              const Gap(AppSpacing.xs),
              GestureDetector(
                onTap: () => ref
                    .read(bookmarkProvider.notifier)
                    .toggle(q.eraId, q.no),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isBookmarked ? AppColors.itPassSeed : c.fgShade300,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),

          // 問題文
          if (q.body.text.isNotEmpty) ...[
            Text(
              q.body.text,
              style:
                  AppTextStyle.bodySmall.copyWith(color: c.fgShade400, height: 1.6),
            ),
            if (q.body.subItems.isNotEmpty) ...[
              const Gap(AppSpacing.xs),
              ...q.body.subItems.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(
                      left: AppSpacing.sm, bottom: AppSpacing.xs),
                  child: Text(
                    s,
                    style: AppTextStyle.bodySmall
                        .copyWith(color: c.fgShade400, height: 1.5),
                  ),
                ),
              ),
            ],
            const Gap(AppSpacing.md),
          ],

          // 選択肢
          ...q.choices.map((choice) {
            final isCorrect = choice.label == q.answer;
            final isSelected = choice.label == item.selectedLabel;
            final borderColor = isCorrect
                ? AppColors.success
                : (isSelected ? AppColors.error : c.border1);
            final bgColor = isCorrect
                ? AppColors.success.withValues(alpha: 0.08)
                : (isSelected
                    ? AppColors.error.withValues(alpha: 0.08)
                    : Colors.transparent);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: AppBorderRadius.md,
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Text(
                      '${choice.label}. ',
                      style: AppTextStyle.labelLarge.copyWith(
                        color: isCorrect
                            ? AppColors.success
                            : (isSelected ? AppColors.error : c.fgShade300),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        choice.text,
                        style: AppTextStyle.bodySmall
                            .copyWith(color: c.fgShade400, height: 1.4),
                      ),
                    ),
                    if (isCorrect)
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 16)
                    else if (isSelected)
                      Icon(Icons.cancel_rounded,
                          color: AppColors.error, size: 16),
                  ],
                ),
              ),
            );
          }),

          Divider(height: AppSpacing.lg, color: c.border1),

          // 解説
          if (q.explanationText.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: c.fg, size: 16),
                const Gap(6),
                Text(
                  '解説',
                  style: AppTextStyle.titleSmall.copyWith(color: c.fg),
                ),
              ],
            ),
            const Gap(AppSpacing.sm),
            Text(
              q.explanationText,
              style: AppTextStyle.bodySmall
                  .copyWith(color: c.fgShade400, height: 1.75),
            ),
          ],

          // 選択肢コメント
          if (q.explanationChoiceComments.isNotEmpty) ...[
            const Gap(AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: AppBorderRadius.sm,
              ),
              child: Column(
                children: q.explanationChoiceComments.asMap().entries.map(
                  (e) {
                    if (e.value.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.xs + 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${String.fromCharCode(97 + e.key)}. ',
                            style: AppTextStyle.bodySmall
                                .copyWith(color: c.fg),
                          ),
                          Expanded(
                            child: Text(
                              e.value,
                              style: AppTextStyle.bodySmall
                                  .copyWith(color: c.fg, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 小バッジ ───────────────────────────────────────────────────

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius:
            AppBorderRadius.sm - const BorderRadius.all(Radius.circular(2)),
      ),
      child: Text(
        label,
        style: AppTextStyle.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
