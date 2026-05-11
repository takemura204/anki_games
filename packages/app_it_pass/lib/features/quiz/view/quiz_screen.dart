import 'dart:math';
import 'dart:ui';

import 'package:app_it_pass/components/checkmark_painter.dart';
import 'package:app_it_pass/components/glass_widget.dart';
import 'package:app_it_pass/components/modal_handle.dart';
import 'package:app_it_pass/features/report/view_model/progress_dashboard_provider.dart';
import 'package:confetti/confetti.dart';
import 'package:core/config/constants/app_urls.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/features/admob/admob_banner.dart';
import 'package:core/features/admob/admob_native.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../router/modal_sheet_router.dart';
import '../../review/repository/review_repository.dart';
import 'modals/result_detail_sheet.dart';
import '../../learning/model/learning_level.dart';
import '../../learning/model/question_learning_stats.dart';
import '../../learning/providers/it_pass_learning_stats_provider.dart';
import '../../learning/repository/local_learning_history_repository.dart';
import '../../note/providers/bookmark_provider.dart';
import '../../note/repository/local_quiz_history_repository.dart';
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

//TODO:FirebaseAuthで連携時にFirestoreでデータ連携を実装してデータ同期
//IDEA:1日の初めはQuizの開始画面でモチベーションを上げる画面を用意してたテスワイプで開始できるようにする。
class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [_QuizGradientBackground(), _QuizBody()],
      ),
    );
  }
}

class _QuizBody extends ConsumerStatefulWidget {
  const _QuizBody();

  @override
  ConsumerState<_QuizBody> createState() => _QuizBodyState();
}

class _QuizBodyState extends ConsumerState<_QuizBody>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final ConfettiController _confettiController;
  late final AnimationController _sheetController;
  late final Animation<Offset> _sheetSlide;

  List<_PageEntry> _pages = const [];
  var _currentViewPage = 0;
  final _resultElapsesBySet = <int, Duration>{};

  var _sheetMounted = false;

  /// シートアニメーション完了後に true になり、_AnsweredActionBar を表示する
  var _actionBarReady = false;

  static const _inlineBannerDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1200),
    );
    _sheetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380), // シートスライドのチューニング値
    )..addStatusListener(_onSheetStatus);
    _sheetSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _sheetController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // ---- helpers ----

  bool get _isOnResultPage =>
      _pages.isNotEmpty && _pages[_currentViewPage] is _ResultEntry;

  bool get _isOnSessionEndPage =>
      _pages.isNotEmpty && _pages[_currentViewPage] is _SessionEndEntry;

  // ---- provider change handler (didUpdateWidget の代替) ----

  void _onProviderChanged(
    AsyncValue<QuizState>? prev,
    AsyncValue<QuizState> next,
  ) {
    final prevSession = prev?.value is QuizReady
        ? (prev!.value as QuizReady).session
        : null;
    final nextSession = next.value is QuizReady
        ? (next.value as QuizReady).session
        : null;

    if (next is AsyncLoading) {
      _pageController.jumpToPage(0);
      setState(() {
        _pages = const [];
        _currentViewPage = 0;
        _sheetMounted = false;
        _actionBarReady = false;
        _resultElapsesBySet.clear();
      });
      return;
    }

    if (nextSession == null) return;

    if (prevSession == null) {
      setState(() {
        _pages = _buildPages(nextSession.totalCount);
        _currentViewPage = 0;
      });
      return;
    }

    if (!prevSession.isAnswered &&
        nextSession.isAnswered &&
        nextSession.answerState == AnswerState.correct) {
      _confettiController.play();
    }

    if (!prevSession.showExplanation &&
        nextSession.showExplanation &&
        nextSession.answerState == AnswerState.incorrect) {
      Future.delayed(_inlineBannerDelay, () {
        if (!mounted) return;
        setState(() => _sheetMounted = true);
        _sheetController.forward(from: 0);
      });
    }

    final setChanged =
        nextSession.currentSetIndex != prevSession.currentSetIndex;
    final looped =
        nextSession.currentIndex == 0 && prevSession.currentIndex != 0;
    if (setChanged || looped) {
      setState(() {
        _pages = _buildPages(nextSession.totalCount);
        _currentViewPage = 0;
        _resultElapsesBySet.clear();
      });
      _pageController.jumpToPage(0);
    }
  }

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
    final quizState = ref.read(quizViewModelProvider).value;
    if (quizState is! QuizReady) return;
    if (!_sheetMounted && quizState.session.showExplanation) {
      setState(() {
        _sheetMounted = true;
        _actionBarReady = false;
      });
      _sheetController.forward(from: 0);
    }
  }

  void _onResultContinue() {
    final quizState = ref.read(quizViewModelProvider).value;
    if (quizState is! QuizReady) return;
    final session = quizState.session;
    if (session.hasNextSet) {
      ref.read(quizViewModelProvider.notifier).nextSet();
    } else {
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
      final quizState = ref.read(quizViewModelProvider).value;
      final elapsed = quizState is QuizReady
          ? quizState.session.setElapsed
          : Duration.zero;
      setState(() {
        _currentViewPage = pageIndex;
        _resultElapsesBySet[entry.setIndex] = elapsed;
      });
      return;
    }

    if (entry is _SessionEndEntry) {
      setState(() {
        _currentViewPage = pageIndex;
      });
      _confettiController.play();
      return;
    }

    setState(() {
      _currentViewPage = pageIndex;
      _sheetMounted = false;
      _actionBarReady = false;
    });

    if (pageIndex > prevPage) {
      ref.read(quizViewModelProvider.notifier).nextQuestion();
    }
  }

  Future<void> _openFilter() async {
    final applied = await ref.read(modalSheetRouterProvider).showFilterSheet();
    if (applied == true) {
      ref.invalidate(quizViewModelProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(quizViewModelProvider);
    ref.read(progressDashboardProvider);
    ref.listen<AsyncValue<QuizState>>(
      quizViewModelProvider,
      _onProviderChanged,
    );

    final quizState = asyncState.value;
    final session = quizState is QuizReady ? quizState.session : null;

    final cardRadius = BorderRadius.circular(90);
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    // 正解: シートなしで即表示 / 不正解: シートアニメーション完了後のみ表示
    final isIncorrect = session?.answerState == AnswerState.incorrect;
    final showActionBar =
        session != null &&
        session.isAnswered &&
        !_isOnResultPage &&
        !_isOnSessionEndPage &&
        (isIncorrect ? _actionBarReady : !_sheetMounted);

    final physics =
        _isOnResultPage ||
            _isOnSessionEndPage ||
            (session != null && session.isAnswered && !_sheetMounted)
        ? const _ForwardOnlyPageScrollPhysics()
        : const NeverScrollableScrollPhysics();

    final headerCenterLabel = _isOnResultPage
        ? 'リザルト'
        : _isOnSessionEndPage
        ? '次のステップ'
        : null;

    return Stack(
      children: [
        asyncState.when(
          loading: () => const _QuizSkeleton(),
          error: (e, _) => _QuizErrorView(
            message: 'データの読み込みに失敗しました\nフィルターを変更してお試しください',
            onOpenFilter: _openFilter,
          ),
          data: (state) {
            if (state is QuizError) {
              return _QuizErrorView(
                message: state.message,
                onOpenFilter: _openFilter,
              );
            }
            if (state is! QuizReady || _pages.isEmpty) {
              return const SizedBox.shrink();
            }
            return PageView.builder(
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
                    session: state.session,
                    elapsed: elapsed,
                    onContinue: _onResultContinue,
                  );
                }

                if (entry is _SessionEndEntry) {
                  return _SessionEndPage(
                    key: const ValueKey('session_end'),
                    onOpenFilter: _openFilter,
                  );
                }

                final e = entry as _QuestionEntry;
                if (e.questionIndex >= state.session.questions.length) {
                  return const SizedBox.shrink();
                }
                final isCurrentPage =
                    e.questionIndex == state.session.currentIndex;
                final pageSession = isCurrentPage
                    ? state.session
                    : QuizSession(
                        allQuestions: state.session.allQuestions,
                        currentSetIndex: state.session.currentSetIndex,
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
            onTapFilter: _openFilter,
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
            onTapReport: () =>
                ref.read(modalSheetRouterProvider).showReportSheet(),
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
        if (_sheetMounted && session != null)
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
