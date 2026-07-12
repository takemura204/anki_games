part of 'quiz_screen.dart';

// ---------------------------------------------------------------------------
// Page entry model
// ---------------------------------------------------------------------------

sealed class _PageEntry {
  const _PageEntry();
}

// Onboarding pages (all extend this base for easy type-checking)
sealed class _OnboardingBaseEntry extends _PageEntry {
  const _OnboardingBaseEntry();
}

final class _OnboardingIntroEntry extends _OnboardingBaseEntry {
  const _OnboardingIntroEntry();
}

final class _OnboardingTrackingEntry extends _OnboardingBaseEntry {
  const _OnboardingTrackingEntry();
}

final class _OnboardingCategoryEntry extends _OnboardingBaseEntry {
  const _OnboardingCategoryEntry();
}

final class _OnboardingQuizEntry extends _OnboardingBaseEntry {
  const _OnboardingQuizEntry();
}

final class _OnboardingFeatureEntry extends _OnboardingBaseEntry {
  const _OnboardingFeatureEntry();
}

final class _OnboardingReviewEntry extends _OnboardingBaseEntry {
  const _OnboardingReviewEntry();
}

final class _OnboardingNotificationEntry extends _OnboardingBaseEntry {
  const _OnboardingNotificationEntry();
}

final class _OnboardingGoalEntry extends _OnboardingBaseEntry {
  const _OnboardingGoalEntry();
}

final class _OnboardingPremiumEntry extends _OnboardingBaseEntry {
  const _OnboardingPremiumEntry();
}

final class _OnboardingDoneEntry extends _OnboardingBaseEntry {
  const _OnboardingDoneEntry();
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

final class _MotivationEntry extends _PageEntry {
  const _MotivationEntry();
}

final class _LoadingEntry extends _PageEntry {
  const _LoadingEntry();
}

List<_PageEntry> _buildPages(int total, {bool includeMotivation = false}) {
  final pages = <_PageEntry>[];
  if (includeMotivation) pages.add(const _MotivationEntry());
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
