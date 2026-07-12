import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:core/components/admob_glass.dart';
import 'package:core/components/checkmark_painter.dart';
import 'package:core/components/explanation_card.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/config/ads/ad_config.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/brand/brand_config.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/lifecycle/app_lifecycle_provider.dart';
import 'package:core/config/lifecycle/lifecycle_observer.dart';
import 'package:core/config/quotes/motivation_quotes.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/admob/admob_interstitial.dart';
import 'package:core/features/exam_quiz/backup/providers/auto_restore_message_provider.dart';
import 'package:core/features/exam_quiz/learning/model/learning_level.dart';
import 'package:core/features/exam_quiz/learning/model/question_learning_stats.dart';
import 'package:core/features/exam_quiz/learning/providers/exam_learning_stats_provider.dart';
import 'package:core/features/exam_quiz/learning/repository/local_learning_history_repository.dart';
import 'package:core/features/exam_quiz/note/providers/bookmark_provider.dart';
import 'package:core/features/exam_quiz/notification/service/notification_service.dart';
import 'package:core/features/exam_quiz/onboarding/view_model/onboarding_ui_notifier.dart';
import 'package:core/features/exam_quiz/onboarding/view_model/onboarding_view_model.dart';
import 'package:core/features/exam_quiz/purchase/repository/local_sale_promo_repository.dart';
import 'package:core/features/exam_quiz/purchase/view/paywall_sheet.dart';
import 'package:core/features/exam_quiz/report/view_model/progress_dashboard_provider.dart';
import 'package:core/features/exam_quiz/review/review_repository.dart';
import 'package:core/features/exam_quiz/router/modal_sheet_router.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shimmer/shimmer.dart';

import '../../onboarding/view/widgets/onboarding_category_page.dart';
import '../../onboarding/view/widgets/onboarding_done_page.dart';
import '../../onboarding/view/widgets/onboarding_feature_page.dart';
import '../../onboarding/view/widgets/onboarding_goal_page.dart';
import '../../onboarding/view/widgets/onboarding_intro_page.dart';
import '../../onboarding/view/widgets/onboarding_notification_page.dart';
import '../../onboarding/view/widgets/onboarding_pay_wall_page.dart';
import '../../onboarding/view/widgets/onboarding_quiz_page.dart';
import '../../onboarding/view/widgets/onboarding_review_page.dart';
import '../../onboarding/view/widgets/onboarding_tracking_page.dart';
import '../analytics/post_result_analytics.dart';
import '../model/quiz_session.dart';
import '../repository/local_quiz_session_count_repository.dart';
import '../repository/motivation_last_shown_repository.dart';
import '../sync/quiz_sync_notifier.dart';
import '../view_model/quiz_view_model.dart';
import 'modals/result_detail_sheet.dart';
import 'widgets/choice_button.dart';
import 'widgets/question_card.dart';

part 'quiz_paging.dart';
part 'quiz_shell_widgets.dart';
part 'widgets/finished_result_page.dart';
part 'widgets/footer.dart';
part 'widgets/header.dart';
part 'widgets/motivation_start_card.dart';
part 'widgets/quiz_page_item.dart';
part 'widgets/quiz_skeleton.dart';
part 'widgets/session_end_page.dart';

class QuizScreen extends HookConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref
      ..listen<String?>(autoRestoreMessageProvider, (_, next) {
        if (next == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), behavior: SnackBarBehavior.floating),
        );
        ref.read(autoRestoreMessageProvider.notifier).update(null);
      })
      ..listen<AppLifecycleData>(appLifecycleProvider, (prev, next) {
        final notifier = ref.read(quizViewModelProvider.notifier);
        // BG復帰: セット解答時間を補正
        final bg = next.lastBgDuration;
        if (bg != null && bg != prev?.lastBgDuration) {
          try {
            notifier.handleResumed(bg);
          } on Object catch (_) {}
        }
      });
    useWidgetLifecycleObserver(context, ref);

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

class _QuizBodyState extends ConsumerState<_QuizBody> {
  late final PageController _pageController;
  late final ConfettiController _confettiController;
  late final AdmobInterstitial _admobInterstitial;
  List<_PageEntry> _pages = const [_MotivationEntry(), _LoadingEntry()];
  var _currentViewPage = 0;
  final _resultElapsesBySet = <int, Duration>{};

  var _hasShownMotivation = false;
  var _isOnboarding = false;

  /// モチベーション画面スワイプ後の自動ジャンプ中は true にして
  /// `nextQuestion` 呼び出しをスキップする。
  var _skipNextQuestion = false;

  /// ユーザーのドラッグ操作によるページ遷移かどうかを追跡する
  var _isUserSwipe = false;

  /// 現在のセッション（セット）でレビューまたは広告を既に表示したかどうか。
  /// nextSet / 全問完了時にリセットする。
  var _postResultShownThisSession = false;

  /// 正解コンフェッティを最後に再生した問題を識別するキー。
  /// 同一問題に対して _onProviderChanged が複数回呼ばれても
  /// play() が一度しか実行されないようにするガード。
  String? _lastConfettiKey;

  /// [_openFilter] からの意図的な invalidate か否かを示すフラグ。
  /// true のときだけ AsyncLoading で _pages をリセットする。
  /// quizSyncProvider の自動再評価や課金状態更新など、
  /// 外部要因による AsyncLoading では画面をリセットしない。
  var _intentionalReset = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1200),
    );
    _admobInterstitial = AdmobInterstitial(ref.read(adConfigProvider));
    _initMotivationVisibility();
  }

  /// セット（10問）の結果ページ表示から3秒後に呼ばれる、1日1回のセール表示。
  ///
  /// 累計2セット以上完了したユーザーのみが対象（初回セッションでは出さない）。
  /// 同セッションでレビュー訴求済み（[_postResultShownThisSession]）の場合は
  /// 訴求が重複するため出さない。
  Future<void> _maybeShowDailySaleAfterResult() async {
    if (!mounted || !_isOnResultPage || _postResultShownThisSession) return;

    final count = await ref.read(quizSessionCountRepositoryProvider).getCount();
    if (count < 1) return;

    if (!mounted || !_isOnResultPage || _postResultShownThisSession) return;
    final shouldShow = await ref
        .read(salePromoRepositoryProvider)
        .checkAndMarkDailySale();
    if (!shouldShow || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallSheet(saleMode: true),
    );
  }

  Future<void> _initMotivationVisibility() async {
    final shouldShow = await MotivationLastShownRepository().shouldShow();
    if (!mounted) return;
    if (!shouldShow) {
      setState(() {
        _hasShownMotivation = true;
        _pages = const [_LoadingEntry()];
      });
    }
    // モチベーション表示判定の後にオンボーディング判定（順番保証）
    await _maybeInitOnboarding();
  }

  Future<void> _maybeInitOnboarding() async {
    final completed = await ref.read(onboardingViewModelProvider.future);
    if (!mounted) return;
    if (!completed) {
      setState(() {
        _isOnboarding = true;
        _hasShownMotivation = true;
        _pages = const [
          _OnboardingIntroEntry(),
          _OnboardingTrackingEntry(),
          _OnboardingNotificationEntry(),
          _OnboardingGoalEntry(),
          _OnboardingCategoryEntry(),
          _OnboardingQuizEntry(),
          _OnboardingFeatureEntry(),
          _OnboardingReviewEntry(),
          _OnboardingPremiumEntry(),
          _OnboardingDoneEntry(),
          _MotivationEntry(),
        ];
      });
    }
  }

  /// チュートリアルリセット後にその場で再初期化する。
  void _reinitForOnboarding() {
    ref.read(onboardingUiProvider.notifier).reset();
    setState(() {
      _isOnboarding = true;
      _hasShownMotivation = false;
      _pages = const [
        _OnboardingIntroEntry(),
        _OnboardingTrackingEntry(),
        _OnboardingNotificationEntry(),
        _OnboardingGoalEntry(),
        _OnboardingCategoryEntry(),
        _OnboardingQuizEntry(),
        _OnboardingFeatureEntry(),
        _OnboardingReviewEntry(),
        _OnboardingPremiumEntry(),
        _OnboardingDoneEntry(),
        _MotivationEntry(),
      ];
      _currentViewPage = 0;
    });
    _pageController.jumpToPage(0);
  }

  /// 現在のオンボーディングページに対応する「次へ」コールバックを返す。
  /// null = 次へボタンを表示しない。
  VoidCallback? _getOnboardingNextCallback() {
    if (!_isOnOnboardingPage) return null;
    final entry = _pages[_currentViewPage];
    final ob = ref.watch(onboardingUiProvider);
    return switch (entry) {
      _OnboardingIntroEntry _ => _goNext,
      _OnboardingTrackingEntry _ => _onTrackingNext, // 次へタップ時にATT/UMP発火
      _OnboardingCategoryEntry _ =>
        ob.selectedSystems.isEmpty ? null : _onCategoryNext,
      _OnboardingQuizEntry _ => ob.quizShowActionBar ? _goNext : null,
      _OnboardingFeatureEntry _ => _goNext,
      _OnboardingReviewEntry _ => _goNext,
      _OnboardingNotificationEntry _ =>
        ob.selectedNotificationSlot == null ? null : _onNotificationNext,
      _OnboardingGoalEntry _ => ob.selectedGoal == null ? null : _onGoalNext,
      _OnboardingPremiumEntry _ => null,
      _OnboardingDoneEntry _ => _goNext,
      _ => null,
    };
  }

  void _onCategoryNext() {
    ref.read(onboardingUiProvider.notifier).submitCategory();
    _goNext();
  }

  Future<void> _onGoalNext() async {
    await ref.read(onboardingUiProvider.notifier).submitGoal();
    if (mounted) _goNext();
  }

  Future<void> _onNotificationNext() async {
    final notifier = ref.read(onboardingUiProvider.notifier)
      ..setNotificationLoading(loading: true);
    final granted = await NotificationService.instance.requestPermission(
      context,
      showSettingsDialogOnDenied: false,
    );
    if (!mounted) return;
    await notifier.saveNotificationSettings(granted: granted);
    if (mounted) _goNext();
  }

  Future<void> _onPremiumPurchase() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final isPremium = await ref
          .read(onboardingUiProvider.notifier)
          .submitPurchase();
      if (isPremium && mounted) _goNext();
    } on Exception catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(t.premium.errorPurchaseFailed)),
        );
      }
    }
  }

  Future<void> _onTrackingNext() async {
    await ref.read(onboardingUiProvider.notifier).submitTracking();
    if (mounted) _goNext();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confettiController.dispose();
    _admobInterstitial.dispose();
    super.dispose();
  }

  // ---- helpers ----

  bool get _isOnMotivationPage =>
      _pages.isNotEmpty && _pages[_currentViewPage] is _MotivationEntry;

  bool get _isOnResultPage =>
      _pages.isNotEmpty && _pages[_currentViewPage] is _ResultEntry;

  bool get _isOnSessionEndPage =>
      _pages.isNotEmpty && _pages[_currentViewPage] is _SessionEndEntry;

  bool get _isOnLoadingPage =>
      _pages.isNotEmpty && _pages[_currentViewPage] is _LoadingEntry;

  bool get _isOnOnboardingPage =>
      _pages.isNotEmpty && _pages[_currentViewPage] is _OnboardingBaseEntry;

  // ---- provider change handler (didUpdateWidget の代替) ----

  void _onProviderChanged(
    AsyncValue<QuizState>? prev,
    AsyncValue<QuizState> next,
  ) {
    if (next.value is QuizPreviewIntro) {
      setState(() {
        _isOnboarding = true;
        _hasShownMotivation = false;
        _pages = const [_OnboardingIntroEntry(), _MotivationEntry()];
        _currentViewPage = 0;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
      return;
    }

    final prevSession = prev?.value is QuizReady
        ? (prev!.value! as QuizReady).session
        : null;
    final nextSession = next.value is QuizReady
        ? (next.value! as QuizReady).session
        : null;

    if (next is AsyncLoading) {
      // フィルター変更など意図的な invalidate のみリセット
      // quizSyncProvider の自動再評価・課金状態更新などの
      // 外部要因による AsyncLoading では画面をリセットしない
      if (_hasShownMotivation && !_isOnboarding && _intentionalReset) {
        _intentionalReset = false;
        _pageController.jumpToPage(0);
        setState(() {
          _pages = const [];
          _currentViewPage = 0;
          _resultElapsesBySet.clear();
        });
      }
      return;
    }

    if (nextSession == null) return;

    if (prevSession == null) {
      // オンボーディング中はクイズページで上書きしない
      if (_isOnboarding) return;
      final pages = _buildPages(
        nextSession.totalCount,
        includeMotivation: !_hasShownMotivation,
      );
      setState(() {
        _pages = pages;
        _currentViewPage = 0;
      });

      // モチベーション画面なし（2回目以降の起動）でリジューム位置があるなら直接ジャンプ
      final resumedIndex = nextSession.currentIndex;
      if (_hasShownMotivation &&
          resumedIndex > 0 &&
          resumedIndex < pages.length - 2) {
        _skipNextQuestion = true;
        _pageController.jumpToPage(resumedIndex);
      } else {
        _pageController.jumpToPage(0);
      }
      return;
    }

    if (!prevSession.isAnswered &&
        nextSession.isAnswered &&
        nextSession.answerState == AnswerState.correct) {
      final key =
          '${nextSession.currentSetIndex}_${nextSession.currentIndex}';
      if (_lastConfettiKey != key) {
        _lastConfettiKey = key;
        _confettiController.play();
      }
    }

    final setChanged =
        nextSession.currentSetIndex != prevSession.currentSetIndex;
    final looped =
        nextSession.currentIndex == 0 && prevSession.currentIndex != 0;
    if (!_isOnboarding && (setChanged || looped)) {
      setState(() {
        _pages = _buildPages(nextSession.totalCount);
        _currentViewPage = 0;
        _resultElapsesBySet.clear();
      });
      _pageController.jumpToPage(0);
    }
  }

  // ---- actions ----

  void _goNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 450), // ページスワイプのチューニング値
      curve: Curves.easeInOutCubic,
    );
  }

  void _onResultContinue() {
    if (ref.read(quizViewModelProvider.notifier).isPreviewMode) {
      ref.read(quizViewModelProvider.notifier).endPreview();
      return;
    }
    final shown = _tryShowPreloadedAdOnContinue(
      onDismissed: _doNavigateFromResult,
    );
    if (!shown) _doNavigateFromResult();
  }

  /// preload 済み広告を出す条件が揃っていれば表示して `true` を返す。
  ///
  /// 表示後は [onDismissed] でナビゲーションを呼び出す。
  /// 表示しなかった場合は `false` を返し、呼び出し元が即時ナビゲートする。
  bool _tryShowPreloadedAdOnContinue({required VoidCallback onDismissed}) {
    if (_postResultShownThisSession) return false;

    final isPremium =
        ref.read(premiumViewModelProvider).asData?.value.isPremium ?? false;
    if (isPremium) return false;

    final last = ref.read(appLifecycleProvider).lastResultAdShownAt;
    final cooldownPassed =
        last == null ||
        DateTime.now().difference(last) >=
            const Duration(minutes: 10); // 結果ページ広告クールダウン
    if (!cooldownPassed) return false;

    if (!_admobInterstitial.hasPreloadedAd) return false;

    _postResultShownThisSession = true;
    ref.read(appLifecycleProvider.notifier).recordResultAdShown();

    final shown = _admobInterstitial.showIfReady(
      onDismissed: () {
        unawaited(PostResultAnalytics.logAdDismiss());
        onDismissed();
      },
    );
    if (shown) {
      unawaited(
        PostResultAnalytics.logResultAction(
          actionType: PostResultAnalytics.actionAd,
          isPremium: isPremium,
        ),
      );
      unawaited(PostResultAnalytics.logAdImpression());
    }
    return shown;
  }

  void _doNavigateFromResult() {
    if (!mounted) return;
    final quizState = ref.read(quizViewModelProvider).value;
    if (quizState is! QuizReady) return;
    final session = quizState.session;
    if (session.hasNextSet) {
      setState(() => _postResultShownThisSession = false);
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
    final prevEntry = _pages[prevPage];
    final entry = _pages[pageIndex];

    // オンボーディングページはクイズロジックをスキップ
    if (entry is _OnboardingBaseEntry) {
      setState(() => _currentViewPage = pageIndex);
      return;
    }

    // オンボーディング中にMotivationPageに到達したら完了処理
    if (entry is _MotivationEntry && _isOnboarding) {
      setState(() {
        _isOnboarding = false;
        _currentViewPage = pageIndex;
      });
      
      if (ref.read(quizViewModelProvider.notifier).isPreviewMode) {
        ref.read(quizViewModelProvider.notifier).startPreviewQuiz();
        return;
      }
      
      unawaited(ref.read(onboardingViewModelProvider.notifier).complete());
      // クイズが既ロード済みならページを再構築（Motivationは引き継ぎ）
      final quizAsync = ref.read(quizViewModelProvider);
      final session = quizAsync.value is QuizReady
          ? (quizAsync.value! as QuizReady).session
          : null;
      if (session != null) {
        final pages = _buildPages(session.totalCount, includeMotivation: true);
        setState(() {
          _hasShownMotivation = false;
          _pages = pages;
          _currentViewPage = 0;
        });
      } else {
        setState(() {
          _hasShownMotivation = false;
          _pages = const [_MotivationEntry(), _LoadingEntry()];
          _currentViewPage = 0;
        });
      }
      _pageController.jumpToPage(0);
      return;
    }

    if (prevEntry is _MotivationEntry && pageIndex > prevPage) {
      _hasShownMotivation = true;
      MotivationLastShownRepository().recordShown();

      // 中断位置が先頭以外なら自動ジャンプ
      final quizState = ref.read(quizViewModelProvider).value;
      if (quizState is QuizReady) {
        final resumedIndex = quizState.session.currentIndex;
        if (resumedIndex > 0 && 1 + resumedIndex < _pages.length - 2) {
          _skipNextQuestion = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _pageController.jumpToPage(1 + resumedIndex);
          });
        }
      }
    }

    if (entry is _ResultEntry) {
      final quizState = ref.read(quizViewModelProvider).value;
      final elapsed = quizState is QuizReady
          ? quizState.session.setElapsed
          : Duration.zero;
      setState(() {
        _currentViewPage = pageIndex;
        _resultElapsesBySet[entry.setIndex] = elapsed;
      });
      ref.read(quizViewModelProvider.notifier).recordSetElapsed(elapsed);
      unawaited(
        ref.read(quizSessionCountRepositoryProvider).increment(),
      );
      unawaited(
        Future.delayed(
          const Duration(seconds: 3),
          _maybeShowDailySaleAfterResult,
        ),
      );
      return;
    }

    if (entry is _SessionEndEntry) {
      setState(() {
        _currentViewPage = pageIndex;
        _postResultShownThisSession = false;
      });
      _confettiController.play();
      ref.read(quizViewModelProvider.notifier).clearResume();
      return;
    }

    final wasUserSwipe = _isUserSwipe;
    _isUserSwipe = false;

    setState(() {
      _currentViewPage = pageIndex;
    });

    if (pageIndex > prevPage && prevEntry is! _MotivationEntry) {
      if (wasUserSwipe) Haptics.of(HapticType.light);
      if (!_skipNextQuestion) {
        ref.read(quizViewModelProvider.notifier).nextQuestion();
      }
      _skipNextQuestion = false;

      // 最終問題（セット内最後の _QuestionEntry）を表示したタイミングで広告を事前ロード
      if (entry is _QuestionEntry) {
        final quizState = ref.read(quizViewModelProvider).value;
        if (quizState is QuizReady &&
            entry.questionIndex == quizState.session.totalCount - 1) {
          final isPremium =
              ref.read(premiumViewModelProvider).asData?.value.isPremium ??
              false;
          if (!isPremium) _admobInterstitial.preload();
        }
      }
    }
  }

  Future<void> _openFilter() async {
    final applied = await ref.read(modalSheetRouterProvider).showFilterSheet();
    if (applied == true) {
      _intentionalReset = true;
      ref.invalidate(quizViewModelProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(quizViewModelProvider);
    ref
      ..read(progressDashboardProvider)
      ..listen<AsyncValue<QuizState>>(
        quizViewModelProvider,
        _onProviderChanged,
      )
      // チュートリアルがリセットされたらその場で再初期化
      ..listen<AsyncValue<bool>>(onboardingViewModelProvider, (prev, next) {
        if (prev?.value == true && next.value == false && mounted) {
          _reinitForOnboarding();
        }
      });

    final quizState = asyncState.value;
    final session = quizState is QuizReady ? quizState.session : null;

    final cardRadius = BorderRadius.circular(90);
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    final showNextButton =
        session != null &&
        session.isAnswered &&
        !_isOnMotivationPage &&
        !_isOnLoadingPage &&
        !_isOnResultPage &&
        !_isOnSessionEndPage &&
        !_isOnOnboardingPage;

    final physics = _isOnboarding
        ? const NeverScrollableScrollPhysics()
        : _isOnMotivationPage ||
              _isOnResultPage ||
              _isOnSessionEndPage ||
              (session != null && session.isAnswered)
        ? const _ForwardOnlyPageScrollPhysics()
        : const NeverScrollableScrollPhysics();

    final headerCenterLabel = _isOnOnboardingPage
        ? null
        : _isOnResultPage
        ? 'リザルト'
        : _isOnSessionEndPage
        ? '次のステップ'
        : null;

    return Stack(
      children: [
        if (_pages.isEmpty)
          asyncState.when(
            loading: () => const _QuizSkeleton(),
            error: (e, _) => _QuizErrorView(
              message: 'データの読み込みに失敗しました\nフィルターを変更してお試しください',
              onOpenFilter: _openFilter,
            ),
            data: (state) => state is QuizError
                ? _QuizErrorView(
                    message: state.message,
                    onOpenFilter: _openFilter,
                  )
                : const SizedBox.shrink(),
          )
        else
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                _isUserSwipe = true;
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: physics,
              itemCount: _pages.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final entry = _pages[index];

                if (entry is _OnboardingIntroEntry) {
                  return const OnboardingIntroPage(key: ValueKey('ob_intro'));
                }

                if (entry is _OnboardingTrackingEntry) {
                  return OnboardingTrackingPage(
                    key: const ValueKey('ob_tracking'),
                    onAllow: _onTrackingNext,
                    appDisplayName: ref
                        .read(brandConfigProvider)
                        .appDisplayName,
                  );
                }

                if (entry is _OnboardingCategoryEntry) {
                  return const OnboardingCategoryPage(
                    key: ValueKey('ob_category'),
                  );
                }

                if (entry is _OnboardingQuizEntry) {
                  return const OnboardingQuizPage(key: ValueKey('ob_quiz'));
                }

                if (entry is _OnboardingFeatureEntry) {
                  return const OnboardingFeaturePage(
                    key: ValueKey('ob_feature'),
                  );
                }

                if (entry is _OnboardingReviewEntry) {
                  return const OnboardingReviewPage(key: ValueKey('ob_review'));
                }

                if (entry is _OnboardingNotificationEntry) {
                  return OnboardingNotificationPage(
                    key: const ValueKey('ob_notification'),
                    isLoading: ref
                        .watch(onboardingUiProvider)
                        .isNotificationLoading,
                  );
                }

                if (entry is _OnboardingGoalEntry) {
                  return const OnboardingGoalPage(key: ValueKey('ob_goal'));
                }

                if (entry is _OnboardingPremiumEntry) {
                  return OnboardingPayWallPage(
                    key: const ValueKey('ob_premium'),
                    onPurchase: _onPremiumPurchase,
                    onSkip: _goNext,
                  );
                }

                if (entry is _OnboardingDoneEntry) {
                  return const OnboardingDonePage(key: ValueKey('ob_done'));
                }

                if (entry is _MotivationEntry) {
                  return _MotivationStartCard(
                    key: const ValueKey('motivation'),
                    quote: MotivationQuotes.pick(DateTime.now()),
                  );
                }

                // ローディングプレースホルダーページ（初回ロード中にスワイプした場合）
                if (entry is _LoadingEntry) {
                  if (asyncState.isLoading) return const _QuizSkeleton();
                  if (asyncState.hasError) {
                    return _QuizErrorView(
                      message: 'データの読み込みに失敗しました\nフィルターを変更してお試しください',
                      onOpenFilter: _openFilter,
                    );
                  }
                  final s = asyncState.value;
                  if (s is QuizError) {
                    return _QuizErrorView(
                      message: s.message,
                      onOpenFilter: _openFilter,
                    );
                  }
                  return const SizedBox.shrink();
                }

                final state = asyncState.value;
                if (state is! QuizReady) return const SizedBox.shrink();

                if (entry is _ResultEntry) {
                  final elapsed =
                      _resultElapsesBySet[entry.setIndex] ?? Duration.zero;
                  return _FinishResultPage(
                    key: ValueKey('result_${entry.setIndex}'),
                    session: state.session,
                    elapsed: elapsed,
                    onContinue: _onResultContinue,
                    onReviewRequested: () =>
                        setState(() => _postResultShownThisSession = true),
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
                  onAnswer: (label) =>
                      ref.read(quizViewModelProvider.notifier).answer(label),
                );
              },
            ),
          ),
        Align(
          alignment: Alignment.topCenter,
          child: _Header(
            cardRadius: cardRadius,
            session: session,
            centerLabel: headerCenterLabel,
            showCenter:
                !_isOnMotivationPage &&
                !_isOnLoadingPage &&
                !_isOnResultPage &&
                !_isOnSessionEndPage &&
                !_isOnOnboardingPage,
            showSideButtons: !_isOnOnboardingPage,
            isOnboarding: _isOnOnboardingPage,
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
            showNextButton: showNextButton,
            onNext: _goNext,
            onTapNote: () => ref.read(modalSheetRouterProvider).showNoteSheet(),
            onTapReport: () =>
                ref.read(modalSheetRouterProvider).showReportSheet(),
            isOnboarding: _isOnOnboardingPage,
            onboardingNextCallback: _getOnboardingNextCallback(),
            isOnboardingNextLoading: ref
                .watch(onboardingUiProvider)
                .isNotificationLoading,
            onboardingNextLabel:
                _pages.isNotEmpty &&
                    _currentViewPage < _pages.length &&
                    _pages[_currentViewPage] is _OnboardingIntroEntry
                ? 'はじめる'
                : '次へ',
          ),
        ),
        _ConfettiOverlay(controller: _confettiController),
      ],
    );
  }
}
