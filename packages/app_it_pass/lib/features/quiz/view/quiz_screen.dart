import 'dart:math';
import 'dart:ui';

import 'package:app_it_pass/components/glass_widget.dart';
import 'package:app_it_pass/components/modal_handle.dart';
import 'package:confetti/confetti.dart';
import 'package:core/config/constants/app_urls.dart';
import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../router/modal_sheet_router.dart';
import '../../learning/model/learning_level.dart';
import '../../learning/providers/it_pass_learning_stats_provider.dart';
import '../../learning/repository/local_learning_history_repository.dart';
import '../../note/providers/bookmark_provider.dart';
import '../model/question.dart';
import '../model/quiz_session.dart';
import '../view_model/quiz_view_model.dart';

import 'widgets/choice_button.dart';
import 'widgets/question_card.dart';
import 'widgets/quiz_network_image.dart';

part 'quiz_paging.dart';
part 'quiz_shell_widgets.dart';
part 'modals/explanation_sheet.dart';
part 'widgets/footer.dart';
part 'widgets/header.dart';
part 'widgets/quiz_page_item.dart';
part 'widgets/quiz_skeleton.dart';
part 'widgets/finished_result_page.dart';

//TODO:NoteSHeetのデザイン調整,FilteSheetのデザイン調整、FinishResultPageとNoteShhetの共通化
//IDEA:1日の初めはQuizの開始画面でモチベーションを上げる画面を用意してたテスワイプで開始できるようにする。
class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(quizViewModelProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _QuizGradientBackground(),
          asyncState.when(
            loading: () => const _QuizSkeleton(),
            error: (e, _) => Center(
              child: Text(
                'エラーが発生しました\n$e',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: context.appColors.fgShade400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            data: (quizState) {
              if (quizState is! QuizReady) {
                return const SizedBox.shrink();
              }
              return _QuizContent(session: quizState.session);
            },
          ),
        ],
      ),
    );
  }
}

class _QuizContent extends ConsumerStatefulWidget {
  const _QuizContent({required this.session});

  final QuizSession session;

  @override
  ConsumerState<_QuizContent> createState() => _QuizContentState();
}

class _QuizContentState extends ConsumerState<_QuizContent>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final ConfettiController _confettiController;
  late final AnimationController _sheetController;
  late final Animation<Offset> _sheetSlide;

  late List<_PageEntry> _pages;
  var _currentViewPage = 0;
  final _resultElapsesBySet = <int, Duration>{};

  var _sheetMounted = false;

  /// シートアニメーション完了後に true になり、_AnsweredActionBar を表示する
  var _actionBarReady = false;

  static const _inlineBannerDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _pages = _buildPages(widget.session.totalCount);

    _pageController = PageController(
      initialPage: _questionPageIndex(widget.session.currentIndex),
    );
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1200),
    );
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380), // シートスライドのチューニング値
    )..addStatusListener(_onSheetStatus);
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _sheetController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(_QuizContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.session.isAnswered &&
        widget.session.isAnswered &&
        widget.session.answerState == AnswerState.correct) {
      _confettiController.play();
    }

    if (!oldWidget.session.showExplanation &&
        widget.session.showExplanation &&
        widget.session.answerState == AnswerState.incorrect) {
      Future.delayed(_inlineBannerDelay, () {
        if (!mounted) {
          return;
        }
        setState(() => _sheetMounted = true);
        _sheetController.forward(from: 0);
      });
    }

    // Questions reshuffled (all done → loop)
    if (widget.session.currentIndex == 0 &&
        oldWidget.session.currentIndex != 0) {
      setState(() {
        _pages = _buildPages(widget.session.totalCount);
        _currentViewPage = 0;
        _resultElapsesBySet.clear();
      });
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // ---- helpers ----

  int _questionPageIndex(int questionIndex) {
    return questionIndex;
  }

  bool get _isOnResultPage =>
      _pages.isNotEmpty && _pages[_currentViewPage] is _ResultEntry;

  bool get _isOnSessionEndPage =>
      _pages.isNotEmpty && _pages[_currentViewPage] is _SessionEndEntry;

  // ---- actions ----

  /// シートアニメーションが完了した瞬間に一度だけ true にセットする。
  /// false へのリセットは _onPageChanged のみが行う。
  void _onSheetStatus(AnimationStatus status) {
    if (!mounted || status != AnimationStatus.completed) {
      return;
    }
    setState(() => _actionBarReady = true);
  }

  void _goNext() {
    _sheetController.reverse();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 450), // ページスワイプのチューニング値
      curve: Curves.easeInOutCubic,
    );
  }

  void _closeSheet() {
    _sheetController.reverse().then((_) {
      if (mounted) {
        setState(() => _sheetMounted = false);
      }
    });
  }

  void _showSheet() {
    if (!_sheetMounted && widget.session.showExplanation) {
      setState(() {
        _sheetMounted = true;
        _actionBarReady = false;
      });
      _sheetController.forward(from: 0);
    }
  }

  void _onResultContinue() {
    if (widget.session.hasNextSet) {
      // 次のセットへ: didUpdateWidget が pages 再構築 + jumpToPage(0) を処理する
      ref.read(quizViewModelProvider.notifier).nextSet();
    } else {
      // 全問完了: SessionEndPage へ進む
      if (_currentViewPage + 1 < _pages.length) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      }
    }
  }

  void _onPageChanged(int pageIndex) {
    final prevPage = _currentViewPage;
    final entry = _pages[pageIndex];

    if (entry is _ResultEntry) {
      setState(() {
        _currentViewPage = pageIndex;
        _resultElapsesBySet[entry.setIndex] = widget.session.setElapsed;
      });
      return;
    }

    if (entry is _SessionEndEntry) {
      setState(() {
        _currentViewPage = pageIndex;
      });
      return;
    }

    // Arrived at a question page
    setState(() {
      _currentViewPage = pageIndex;
      _sheetMounted = false;
      _actionBarReady = false;
    });

    if (pageIndex > prevPage) {
      ref.read(quizViewModelProvider.notifier).nextQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final cardRadius = BorderRadius.circular(90);
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    // 正解: シートなしで即表示 / 不正解: シートアニメーション完了後のみ表示
    final isIncorrect = session.answerState == AnswerState.incorrect;
    final showActionBar = session.isAnswered &&
        !_isOnResultPage &&
        !_isOnSessionEndPage &&
        (isIncorrect ? _actionBarReady : !_sheetMounted);

    final physics = _isOnResultPage ||
            _isOnSessionEndPage ||
            (session.isAnswered && !_sheetMounted)
        ? const _ForwardOnlyPageScrollPhysics()
        : const NeverScrollableScrollPhysics();

    final headerCenterLabel = _isOnResultPage
        ? 'リザルト'
        : _isOnSessionEndPage
            ? '次のステップ'
            : null;

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: physics,
          itemCount: _pages.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final entry = _pages[index];

            if (entry is _ResultEntry) {
              final elapsed =
                  _resultElapsesBySet[entry.setIndex] ?? Duration.zero;
              return _FinishResultPage(
                key: ValueKey('result_${entry.setIndex}'),
                session: session,
                elapsed: elapsed,
                onContinue: _onResultContinue,
              );
            }

            if (entry is _SessionEndEntry) {
              return _SessionEndPage(
                key: const ValueKey('session_end'),
                onOpenFilter: () async {
                  final applied = await ref
                      .read(modalSheetRouterProvider)
                      .showFilterSheet();
                  if (applied == true) {
                    ref.invalidate(quizViewModelProvider);
                  }
                },
              );
            }

            final e = entry as _QuestionEntry;
            final isCurrentPage = e.questionIndex == session.currentIndex;
            final pageSession = isCurrentPage
                ? session
                : QuizSession(
                    allQuestions: session.allQuestions,
                    currentSetIndex: session.currentSetIndex,
                    currentIndex: e.questionIndex,
                  );
            return _QuizPageItem(
              session: pageSession,
              topPadding: top,
              bottomPadding: bottom,
              isSheetOpen: _sheetMounted && isCurrentPage,
              onAnswer: (label) =>
                  ref.read(quizViewModelProvider.notifier).answer(label),
            );
          },
        ),
        Align(
          alignment: Alignment.topCenter,
          child: _Header(
            cardRadius: cardRadius,
            session: session,
            centerLabel: headerCenterLabel,
            showCenter: !_isOnResultPage && !_isOnSessionEndPage,
            onTapSetting: () =>
                ref.read(modalSheetRouterProvider).showSettings(),
            onTapFilter: () async {
              final applied =
                  await ref.read(modalSheetRouterProvider).showFilterSheet();
              if (applied == true) {
                ref.invalidate(quizViewModelProvider);
              }
            },
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _Footer(
            cardRadius: cardRadius,
            session: session,
            showActionBar: showActionBar,
            onShowExplanation: _showSheet,
            onNext: _goNext,
            onTapNote: () => ref.read(modalSheetRouterProvider).showNoteSheet(),
            onTapReport: () async {},
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: pi / 2,
            numberOfParticles: 30,
            gravity: 0.3,
            emissionFrequency: 0.06,
            colors: const [
              AppColors.success,
              AppColors.itPassSeed,
              AppColors.itPassAccent,
              AppColors.warning,
              Color(0xFF60A5FA),
            ],
          ),
        ),
        if (_sheetMounted)
          _ExplanationSheet(
            sheetController: _sheetController,
            slideAnimation: _sheetSlide,
            question: session.currentQuestion,
            selectedLabel: session.selectedLabel ?? '',
            isLast: false,
            onNext: _goNext,
            onDismiss: _closeSheet,
          ),
      ],
    );
  }
}
