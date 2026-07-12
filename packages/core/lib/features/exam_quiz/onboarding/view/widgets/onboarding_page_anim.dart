import 'package:flutter/material.dart';

/// オンボーディング各ページで共通する2グループ フェード+スライドアニメーション。
///
/// - [topFade] / [topSlide]    : ヘッダー（アイコン・タイトル）グループ
/// - [bottomFade] / [bottomSlide] : コンテンツ（リスト・フォーム）グループ
class OnboardingPageAnim {

  /// [ctrl] の duration は 700ms を推奨。
  factory OnboardingPageAnim.from(AnimationController ctrl) {
    const offset = Offset(0, 0.04);
    return OnboardingPageAnim._(
      topFade: CurvedAnimation(
        parent: ctrl,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
      topSlide: Tween<Offset>(begin: offset, end: Offset.zero).animate(
        CurvedAnimation(
          parent: ctrl,
          curve: const Interval(0, 0.65, curve: Curves.easeOutCubic),
        ),
      ),
      bottomFade: CurvedAnimation(
        parent: ctrl,
        curve: const Interval(0.35, 0.95, curve: Curves.easeOut),
      ),
      bottomSlide: Tween<Offset>(begin: offset, end: Offset.zero).animate(
        CurvedAnimation(
          parent: ctrl,
          curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
        ),
      ),
    );
  }
  OnboardingPageAnim._({
    required this.topFade,
    required this.topSlide,
    required this.bottomFade,
    required this.bottomSlide,
  });

  final Animation<double> topFade;
  final Animation<Offset> topSlide;
  final Animation<double> bottomFade;
  final Animation<Offset> bottomSlide;
}

/// [fade] + [slide] を1つの [child] に適用するユーティリティ Widget。
class OnboardingFadeSlide extends StatelessWidget {
  const OnboardingFadeSlide({
    super.key,
    required this.fade,
    required this.slide,
    required this.child,
  });

  final Animation<double> fade;
  final Animation<Offset> slide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
