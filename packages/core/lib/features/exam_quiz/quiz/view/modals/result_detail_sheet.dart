import 'dart:ui';

import 'package:core/components/admob_glass.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/components/modal_handle.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/constants/app_urls.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:core/features/exam_quiz/learning/model/question_learning_stats.dart';
import 'package:core/features/exam_quiz/learning/providers/learning_history_provider.dart';
import 'package:core/features/exam_quiz/learning/repository/local_learning_history_repository.dart'
    show LocalLearningHistoryRepository;
import 'package:core/features/exam_quiz/note/providers/bookmark_provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../model/quiz_session.dart';
import '../widgets/choice_button.dart';
import '../widgets/question_card.dart';

class ResultDetailSheet extends ConsumerStatefulWidget {
  const ResultDetailSheet({
    super.key,
    required this.results,
    required this.initialIndex,
  });

  final List<QuestionResult> results;
  final int initialIndex;

  @override
  ConsumerState<ResultDetailSheet> createState() => _ResultDetailSheetState();
}

class _ResultDetailSheetState extends ConsumerState<ResultDetailSheet> {
  late int _currentIndex;
  late final PageController _pageController;
  Map<String, QuestionLearningStats> _learningStats = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats =
        await (await ref.read(learningHistoryRepositoryProvider.future))
            .loadAll();
    if (mounted) setState(() => _learningStats = stats);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goPrev() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final screenHeight = MediaQuery.of(context).size.height;

    final liveBookmarks = switch (ref.watch(bookmarkProvider)) {
      AsyncData(:final value) => value,
      _ => const <String>{},
    };

    final currentQ = widget.results[_currentIndex].question;
    final isBookmarked = liveBookmarks.contains(
      LocalLearningHistoryRepository.storageKey(currentQ.eraId, currentQ.no),
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: screenHeight * 0.88,
          decoration: BoxDecoration(
            color: c.surfaceSheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: c.border1)),
          ),
          child: Column(
            children: [
              const ModalHandle(),
              _SheetHeader(
                title: 'Q${currentQ.no}. ${currentQ.title}',
                isBookmarked: isBookmarked,
                onBookmark: () => ref
                    .read(bookmarkProvider.notifier)
                    .toggle(currentQ.eraId, currentQ.no),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemCount: widget.results.length,
                  itemBuilder: (context, index) {
                    final result = widget.results[index];
                    final q = result.question;
                    final statsKey = LocalLearningHistoryRepository.storageKey(
                      q.eraId,
                      q.no,
                    );
                    final level = LearningLevel.fromStats(
                      _learningStats[statsKey],
                    );
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.xs,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          QuizQuestionCard(question: q, learningLevel: level),
                          const Gap(12),
                          ...q.choices.map(
                            (choice) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: QuizChoiceButton(
                                choice: choice,
                                questionNo: q.no,
                                correctLabel: q.answer,
                                isAnswered: true,
                                selectedLabel: result.selectedLabel,
                              ),
                            ),
                          ),
                          if (q.explanationText.isNotEmpty) ...[
                            const Gap(AppSpacing.sm),
                            Divider(height: AppSpacing.lg, color: c.border1),
                            Row(
                              children: [
                                Icon(
                                  AppIcons.explanation,
                                  color: c.fgShade400,
                                  size: 20,
                                ),
                                const Gap(6),
                                Text(
                                  '解説',
                                  style: AppTextStyle.titleMedium.copyWith(
                                    color: c.fgShade400,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(AppSpacing.sm),
                            Text(
                              q.explanationText,
                              style: AppTextStyle.bodyLarge.copyWith(
                                color: c.fg,
                                height: 1.75,
                              ),
                            ),
                          ],
                          if (q.explanationChoiceComments.isNotEmpty) ...[
                            const Gap(AppSpacing.md),
                            _ChoiceCommentsBox(
                              comments: q.explanationChoiceComments,
                              colors: c,
                            ),
                          ],
                          const Gap(AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: (() => launchUrl(
                                  Uri.parse(AppUrls.contact),
                                  mode: LaunchMode.externalApplication,
                                )).withHaptic(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      AppIcons.flag,
                                      color: c.fgShade300,
                                      size: 14,
                                    ),
                                    const Gap(3),
                                    Text(
                                      '誤りを報告',
                                      style: AppTextStyle.labelSmall.copyWith(
                                        color: c.fgShade300,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Created by Gimini',
                                style: AppTextStyle.captionSmall.copyWith(
                                  color: c.fgShade300,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const Gap(AppSpacing.md),
                          const AdmobNativeGlass(),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _SheetFooter(
                canGoPrev: _currentIndex > 0,
                canGoNext: _currentIndex < widget.results.length - 1,
                onPrev: _goPrev,
                onNext: _goNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.isBookmarked,
    required this.onBookmark,
  });

  final String title;
  final bool isBookmarked;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyle.titleMedium.copyWith(
                color: c.fg,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Gap(AppSpacing.xs),
          GlassButton(
            cardRadius: AppBorderRadius.circle,
            child: IconButton(
              icon: Icon(
                isBookmarked ? AppIcons.bookmarked : AppIcons.bookmark,
                color: isBookmarked ? AppPalette.seed : c.fgShade300,
              ),
              onPressed: onBookmark.withHaptic(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetFooter extends StatelessWidget {
  const _SheetFooter({
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
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
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
                    onPressed: canGoPrev ? onPrev.withHaptic() : null,
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
                    onPressed: canGoNext ? onNext.withHaptic() : null,
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

class _ChoiceCommentsBox extends StatelessWidget {
  const _ChoiceCommentsBox({required this.comments, required this.colors});

  final List<String> comments;
  final AppColorScheme colors;

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
            padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2.0),
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
