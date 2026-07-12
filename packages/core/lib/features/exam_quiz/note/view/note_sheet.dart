import 'dart:ui';

import 'package:core/components/buttons.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/components/modal_handle.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/constants/app_urls.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/admob/admob_banner.dart';
import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:core/features/exam_quiz/learning/providers/learning_history_provider.dart';
import 'package:core/features/exam_quiz/learning/repository/local_learning_history_repository.dart'
    show LocalLearningHistoryRepository;
import 'package:core/features/exam_quiz/note/model/note_list_item.dart';
import 'package:core/features/exam_quiz/note/providers/bookmark_provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../quiz/view/widgets/choice_button.dart';
import '../../quiz/view/widgets/question_card.dart';
import '../view_model/note_sheet_view_model.dart';

part 'widgets/header.dart';
part 'widgets/note_detail_page.dart';
part 'widgets/note_detail_view.dart';
part 'widgets/note_list_content.dart';
part 'widgets/note_list_item_card.dart';
part 'widgets/note_list_page.dart';
part 'widgets/tab_bar.dart';

class _DetailPageArgs {
  const _DetailPageArgs({
    required this.initialItem,
    required this.fromReview,
    required this.reviewQueue,
    required this.initialIndex,
  });

  final NoteListItem initialItem;
  final bool fromReview;
  final List<NoteListItem> reviewQueue;
  final int initialIndex;
}

class _PushSlidePage<T> extends Page<T> {
  const _PushSlidePage({required this.child, super.key, super.name});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => child,
      transitionsBuilder: (_, animation, _, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0, 0.7),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class NoteSheet extends ConsumerStatefulWidget {
  const NoteSheet({super.key});

  @override
  ConsumerState<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends ConsumerState<NoteSheet> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  _DetailPageArgs? _detailArgs;
  int _detailCurrentIndex = 0;

  void _openDetail(
    NoteListItem item, {
    bool fromReview = false,
    List<NoteListItem>? reviewQueue,
    int reviewIndex = 0,
  }) {
    setState(() {
      _detailArgs = _DetailPageArgs(
        initialItem: item,
        fromReview: fromReview,
        reviewQueue: reviewQueue ?? [item],
        initialIndex: reviewIndex,
      );
      _detailCurrentIndex = reviewIndex;
    });
  }

  void _onDetailPageChanged(int index) {
    setState(() {
      _detailCurrentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    final liveBookmarks = switch (ref.watch(bookmarkProvider)) {
      AsyncData(:final value) => value,
      _ => const <String>{},
    };

    final currentDetailItem = _detailArgs != null
        ? _detailArgs!.reviewQueue[_detailCurrentIndex]
        : null;
    final isBookmarked =
        currentDetailItem != null &&
        liveBookmarks.contains(
          LocalLearningHistoryRepository.storageKey(
            currentDetailItem.question.eraId,
            currentDetailItem.question.no,
          ),
        );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: screenHeight * 0.85,
          decoration: BoxDecoration(
            color: context.appColors.surfaceSheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: context.appColors.border1)),
          ),
          child: Column(
            children: [
              const ModalHandle(),
              _Header(
                isDetail: _detailArgs != null,
                onClose: () => Navigator.of(context).pop(),
                onBack: () => _navigatorKey.currentState?.maybePop(),
                onBookmark: () => ref
                    .read(bookmarkProvider.notifier)
                    .toggle(
                      currentDetailItem!.question.eraId,
                      currentDetailItem.question.no,
                    ),
                isBookmarked: isBookmarked,
                current: _detailArgs == null ? 0 : _detailCurrentIndex + 1,
                total: _detailArgs?.reviewQueue.length ?? 0,
              ),
              Expanded(
                child: PopScope(
                  canPop: _detailArgs == null,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop && _detailArgs != null) {
                      _navigatorKey.currentState?.maybePop();
                    }
                  },
                  child: Navigator(
                    key: _navigatorKey,
                    onDidRemovePage: (_) {
                      if (_detailArgs != null) {
                        setState(() => _detailArgs = null);
                      }
                    },
                    pages: [
                      _PushSlidePage(
                        key: const ValueKey('note_list'),
                        child: _NoteListPage(onSelectItem: _openDetail),
                      ),
                      if (_detailArgs != null)
                        _PushSlidePage(
                          key: ValueKey('note_detail_${_detailArgs.hashCode}'),
                          child: _NoteDetailPage(
                            args: _detailArgs!,
                            onReviewAnswered: () =>
                                ref.invalidate(noteSheetViewModelProvider),
                            onPageChanged: _onDetailPageChanged,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
