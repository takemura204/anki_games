part of 'quiz_screen.dart';

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
