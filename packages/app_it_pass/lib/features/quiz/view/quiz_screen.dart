import 'dart:math';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:core/config/constants/app_urls.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../filter/view/filter_sheet.dart';
import '../../learning/model/learning_level.dart';
import '../../learning/providers/it_pass_learning_stats_provider.dart';
import '../../learning/repository/local_learning_history_repository.dart';
import '../model/question.dart';
import '../model/quiz_session.dart';
import '../view_model/quiz_view_model.dart';

part 'modals/explanation_sheet.dart';
part 'widgets/choice_button.dart';
part 'widgets/footer.dart';
part 'widgets/header.dart';
part 'widgets/question_cardt.dart';
part 'widgets/quiz_network_image.dart';
part 'widgets/quiz_page_item.dart';
part 'widgets/session_finished_widget.dart';

// ---------------------------------------------------------------------------
// Page entry model
// ---------------------------------------------------------------------------

sealed class _PageEntry {
  const _PageEntry();
}

final class _QuestionEntry extends _PageEntry {
  const _QuestionEntry({
    required this.questionIndex,
    required this.setIndex,
  });

  final int questionIndex;
  final int setIndex;
}

final class _ResultEntry extends _PageEntry {
  const _ResultEntry({required this.setIndex});

  final int setIndex;
}

final class _SessionEndEntry extends _PageEntry {
  const _SessionEndEntry();
}

List<_PageEntry> _buildPages(int total) {
  final pages = <_PageEntry>[];
  for (var i = 0; i < total; i++) {
    pages.add(_QuestionEntry(questionIndex: i, setIndex: 0));
  }
  pages
    ..add(const _ResultEntry(setIndex: 0))
    ..add(const _SessionEndEntry());
  return pages;
}

// ---------------------------------------------------------------------------
// Forward-only scroll physics (prevents backward page swipe)
// ---------------------------------------------------------------------------

class _ForwardOnlyPageScrollPhysics extends PageScrollPhysics {
  const _ForwardOnlyPageScrollPhysics({super.parent});

  @override
  _ForwardOnlyPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ForwardOnlyPageScrollPhysics(parent: buildParent(ancestor));
  }

  /// 後退方向（下スワイプ: offset > 0）のみブロックする。
  /// バリスティックアニメーション（ページスナップ）は妨げない。
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (offset > 0) {
      return 0;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }
}

// ---------------------------------------------------------------------------
// Root widget
// ---------------------------------------------------------------------------

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
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, _) => Center(
              child: Text(
                'エラーが発生しました\n$e',
                style: const TextStyle(color: Colors.white70),
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

// ---------------------------------------------------------------------------
// Content (stateful)
// ---------------------------------------------------------------------------

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
      duration: const Duration(milliseconds: 380),
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
      duration: const Duration(milliseconds: 450),
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
    if (_currentViewPage + 1 < _pages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
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

  // ---- build ----

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
        ? 'セット結果'
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
              return _SetResultPage(
                key: ValueKey('result_${entry.setIndex}'),
                session: session,
                elapsed: elapsed,
                onContinue: _onResultContinue,
              );
            }

            if (entry is _SessionEndEntry) {
              return _SessionEndPage(
                key: const ValueKey('session_end'),
                onOpenFilter: () => showQuizFilterSheet(context, ref),
              );
            }

            final e = entry as _QuestionEntry;
            final isCurrentPage = e.questionIndex == session.currentIndex;
            final pageSession = isCurrentPage
                ? session
                : QuizSession(
                    questions: session.questions,
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
            onUserPressed: () {},
            onFilterPressed: () => showQuizFilterSheet(context, ref),
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
            onUserPressed: () {},
            onFilterPressed: () => showQuizFilterSheet(context, ref),
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
              Color(0xFF10B981),
              Color(0xFF7C3AED),
              Color(0xFF4F46E5),
              Color(0xFFFBBF24),
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

// ---------------------------------------------------------------------------
// Answered action bar
// ---------------------------------------------------------------------------

class _AnsweredActionBar extends StatelessWidget {
  const _AnsweredActionBar({
    required this.onShowExplanation,
    required this.onNext,
  });

  final VoidCallback onShowExplanation;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onShowExplanation,
                  icon: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
                  label: const Text(
                    '解説を見る',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white12),
              Expanded(
                child: TextButton.icon(
                  onPressed: onNext,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  label: const Text(
                    '次の問題へ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
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

// ---------------------------------------------------------------------------
// Gradient background
// ---------------------------------------------------------------------------

class _QuizGradientBackground extends StatelessWidget {
  const _QuizGradientBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0B2B),
            Color(0xFF1A0A3C),
            Color(0xFF2D1B69),
          ],
        ),
      ),
    );
  }
}
