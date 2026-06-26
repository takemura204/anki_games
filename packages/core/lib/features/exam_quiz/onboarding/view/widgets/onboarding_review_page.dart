import 'package:core/components/adaptive_body.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/config/brand/it_pass_color_scheme.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/onboarding/view/widgets/onboarding_page_anim.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class OnboardingReviewPage extends StatefulWidget {
  const OnboardingReviewPage({super.key});

  @override
  State<OnboardingReviewPage> createState() => _OnboardingReviewPageState();
}

class _OnboardingReviewPageState extends State<OnboardingReviewPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final OnboardingPageAnim _anim;

  static const _reviews = [
    _ReviewData(
      stars: 5,
      comment: '1ヶ月の学習で合格できました！解説が丁寧でわかりやすく、苦手な分野も克服できました。',
      reviewer: '20代男性',
    ),
    _ReviewData(
      stars: 5,
      comment: '通勤中に毎日少しずつ続けられました。毎日の積み重ねで、自分の状況が見えるようになり、試験への不安がなくなりました。',
      reviewer: '30代女性',
    ),
    _ReviewData(
      stars: 5,
      comment: 'レベルに合わせた出題がありがたい。最初は難しかったけど徐々に正解率が上がって自信がつきました。',
      reviewer: '10代男性',
    ),
    _ReviewData(
      stars: 5,
      comment: 'SNSタイムをこのアプリに変更。シンプルなデザインでサクサク勉強できるので心理的なハードルが下がりました。',
      reviewer: '20代女性',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _anim = OnboardingPageAnim.from(_ctrl);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.of(context).padding.bottom;

    return AdaptiveBody(
      child: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xxl,
          AppSpacing.md,
          bottom + 80 + AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Group 1: ヘッダー
            OnboardingFadeSlide(
              fade: _anim.topFade,
              slide: _anim.topSlide,
              child: Column(
                children: [
                  Icon(Icons.people, color: c.fg, size: 40),
                  const Gap(AppSpacing.sm),
                  Text(
                    '多くの方に\n選ばれています',
                    style: AppTextStyle.titleLarge.copyWith(
                      color: c.fg,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.xl),
            // Group 2: レビューカード一覧
            OnboardingFadeSlide(
              fade: _anim.bottomFade,
              slide: _anim.bottomSlide,
              child: Column(
                children: _reviews
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _ReviewCard(data: r),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _ReviewData {
  const _ReviewData({
    required this.stars,
    required this.comment,
    required this.reviewer,
  });

  final int stars;
  final String comment;
  final String reviewer;
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.data});

  final _ReviewData data;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GlassContainer(
      cardRadius: AppBorderRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                data.stars,
                (_) => const Icon(
                  Icons.star_rounded,
                  color: AppColors.warning,
                  size: 16,
                ),
              ),
              const Spacer(),
              Text(
                data.reviewer,
                style: AppTextStyle.labelSmall.copyWith(
                  color: c.fgShade300,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          Text(
            data.comment,
            style: AppTextStyle.bodySmall.copyWith(color: c.fg, height: 1.6),
          ),
        ],
      ),
    );
  }
}
