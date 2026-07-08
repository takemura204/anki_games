import 'package:core/components/adaptive_body.dart';
import 'package:core/components/buttons.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/constants/app_urls.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/onboarding/repository/local_study_goal_repository.dart';
import 'package:core/features/exam_quiz/onboarding/view/widgets/onboarding_page_anim.dart';
import 'package:core/features/exam_quiz/onboarding/view_model/onboarding_ui_notifier.dart';
import 'package:core/features/purchase/model/plan_type.dart';
import 'package:core/features/purchase/model/pricing.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingPayWallPage extends HookConsumerWidget {
  const OnboardingPayWallPage({
    super.key,
    required this.onPurchase,
    required this.onSkip,
  });

  final VoidCallback onPurchase;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );
    final anim = useMemoized(() => OnboardingPageAnim.from(ctrl));

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ctrl.isAnimating || ctrl.isCompleted) return;
        ctrl.forward();
      });
      return null;
    }, const []);

    final ob = ref.watch(onboardingUiProvider);
    final notifier = ref.read(onboardingUiProvider.notifier);
    final isPremium =
        ref.watch(premiumViewModelProvider).asData?.value.isPremium ?? false;
    final pricingAsync = ref.watch(pricingProvider);
    final recommendedPlanAsync = ref.watch(recommendedPlanProvider);
    final c = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).padding.bottom;
    final pricing = pricingAsync.asData?.value ?? const Pricing();
    final recommendedPlan =
        recommendedPlanAsync.asData?.value ?? PlanType.monthly;

    return AdaptiveBody(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
            bottom + AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingFadeSlide(
                fade: anim.topFade,
                slide: anim.topSlide,
                child: _PremiumHeader(c: c, colorScheme: colorScheme),
              ),
              const Gap(AppSpacing.lg),
              OnboardingFadeSlide(
                fade: anim.bottomFade,
                slide: anim.bottomSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isPremium)
                      _PremiumActiveCard(c: c, onClose: onSkip)
                    else ...[
                      _PremiumFeatureListSection(c: c),
                      const Gap(AppSpacing.md),
                      _PremiumPlanSelectorSection(
                        c: c,
                        selectedPlan: ob.selectedPlan,
                        pricing: pricing,
                        isLoading: pricingAsync.isLoading,
                        recommendedPlan: recommendedPlan,
                        onSelect: notifier.selectPlan,
                      ),
                      const Gap(AppSpacing.lg),
                      PrimaryButton(
                        label: 'プレミアムを体験する',
                        onPressed:
                            (ob.isPurchaseLoading || pricingAsync.isLoading)
                            ? null
                            : onPurchase,
                        isLoading: ob.isPurchaseLoading,
                        height: 60,
                      ),
                      const Gap(AppSpacing.sm),
                      TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        child: Text(
                          'あとにする',
                          style: AppTextStyle.bodySmall.copyWith(
                            color: c.fgShade400,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: c.fgShade400,
                          ),
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PremiumSmallLink(
                            label: t.premium.restoreButton,
                            onTap: () => ref
                                .read(premiumViewModelProvider.notifier)
                                .restore(),
                            c: c,
                          ),
                          Text(
                            '·',
                            style: TextStyle(fontSize: 11, color: c.fgShade200),
                          ),
                          _PremiumSmallLink(
                            label: t.premium.terms,
                            onTap: () => launchUrl(
                              Uri.parse(AppUrls.termsOfService),
                              mode: LaunchMode.externalApplication,
                            ),
                            c: c,
                          ),
                          Text(
                            '·',
                            style: TextStyle(fontSize: 11, color: c.fgShade200),
                          ),
                          _PremiumSmallLink(
                            label: t.premium.eula,
                            onTap: () => launchUrl(
                              Uri.parse(AppUrls.appleStandardEula),
                              mode: LaunchMode.externalApplication,
                            ),
                            c: c,
                          ),
                          Text(
                            '·',
                            style: TextStyle(fontSize: 11, color: c.fgShade200),
                          ),
                          _PremiumSmallLink(
                            label: t.premium.privacy,
                            onTap: () => launchUrl(
                              Uri.parse(AppUrls.privacyPolicy),
                              mode: LaunchMode.externalApplication,
                            ),
                            c: c,
                          ),
                        ],
                      ),
                      const Gap(AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Text(
                          t.premium.subscriptionDisclosure,
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 8, color: c.fgShade300),
                        ),
                      ),
                      const Gap(AppSpacing.md),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({required this.c, required this.colorScheme});
  final AppColorScheme c;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.sm),
          cardRadius: AppBorderRadius.circle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium_rounded, size: 20, color: c.fg),
              const Gap(AppSpacing.xs),
              Text(
                'Premium',
                style: AppTextStyle.titleSmall.copyWith(
                  color: c.fg,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Gap(AppSpacing.md),
        Text(
          '本気で勉強したい人向けのプラン',
          style: AppTextStyle.labelLarge.copyWith(color: c.fg),
        ),
      ],
    );
  }
}

class _PremiumFeatureListSection extends StatelessWidget {
  const _PremiumFeatureListSection({required this.c});
  final AppColorScheme c;

  static const List<(IconData, String, String)> _features = [
    (Icons.block_outlined, '広告', '非表示'),
    (Icons.auto_stories_outlined, '学習範囲', '全問解放'),
    (Icons.school_outlined, '1日の学習数', '無制限'),
    (AppIcons.report, 'レポート', '全解放'),
    (Icons.sync_outlined, 'データ同期', '自動更新'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: GlassContainer(
        cardRadius: BorderRadius.circular(14),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < _features.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    GlassContainer(
                      cardRadius: AppBorderRadius.sm,
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(_features[i].$1, size: 20, color: c.fg),
                    ),
                    const Gap(AppSpacing.sm),
                    Text(
                      _features[i].$2,
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: c.fg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _features[i].$3,
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: c.fgShade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < _features.length - 1)
                Divider(
                  height: 1,
                  indent: 14,
                  endIndent: 14,
                  color: c.fgShade50,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumPlanSelectorSection extends StatelessWidget {
  const _PremiumPlanSelectorSection({
    required this.c,
    required this.selectedPlan,
    required this.pricing,
    required this.isLoading,
    required this.recommendedPlan,
    required this.onSelect,
  });
  final AppColorScheme c;
  final PlanType selectedPlan;
  final Pricing pricing;
  final bool isLoading;
  final PlanType recommendedPlan;
  final void Function(PlanType) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: GlassButton(
        cardRadius: AppBorderRadius.md,
        child: Column(
          children: [
            _PlanRow(
              title: '1ヶ月プラン',
              subtitle: '毎月更新。いつでもキャンセル可能。',
              plan: PlanType.monthly,
              pricing: pricing,
              isLoading: isLoading,
              isSelected: selectedPlan == PlanType.monthly,
              isRecommended: recommendedPlan == PlanType.monthly,
              onTap: () => onSelect(PlanType.monthly),
              c: c,
            ),
            Divider(height: 1, indent: 14, endIndent: 14, color: c.fgShade50),
            _PlanRow(
              title: '買い切りプラン',
              subtitle: '合格まで使い放題。追加課金なし。',
              plan: PlanType.lifetime,
              pricing: pricing,
              isLoading: isLoading,
              isSelected: selectedPlan == PlanType.lifetime,
              isRecommended: recommendedPlan == PlanType.lifetime,
              onTap: () => onSelect(PlanType.lifetime),
              c: c,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.title,
    required this.subtitle,
    required this.plan,
    required this.pricing,
    required this.isLoading,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
    required this.c,
  });
  final String title;
  final String subtitle;
  final PlanType plan;
  final Pricing pricing;
  final bool isLoading;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;
  final AppColorScheme c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap.withHaptic(HapticType.selection),
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        decoration: BoxDecoration(
          color: isSelected
              ? AppPalette.seed.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppPalette.seed : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: AppBorderRadius.md,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: AppAnimation.fast,
              child: isSelected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      key: ValueKey('checked'),
                      size: 22,
                      color: AppPalette.seed,
                    )
                  : Icon(
                      Icons.radio_button_unchecked_rounded,
                      key: const ValueKey('unchecked'),
                      size: 22,
                      color: c.fgShade200,
                    ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: c.fg,
                        ),
                      ),
                      if (isRecommended) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.fg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'おすすめ',
                            style: AppTextStyle.labelSmall.copyWith(
                              color: AppPalette.seed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyle.labelSmall.copyWith(
                      color: c.fgShade400,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: c.fg),
              )
            else
              _NormalPriceText(pricing: pricing, plan: plan, c: c),
          ],
        ),
      ),
    );
  }
}

class _NormalPriceText extends StatelessWidget {
  const _NormalPriceText({
    required this.pricing,
    required this.plan,
    required this.c,
  });

  final Pricing pricing;
  final PlanType plan;
  final AppColorScheme c;

  @override
  Widget build(BuildContext context) {
    final price = plan == PlanType.monthly
        ? pricing.monthlyNormal
        : pricing.lifetimeNormal;
    final suffix = plan == PlanType.monthly ? '/月' : '';
    if (price == null) return const SizedBox.shrink();
    return Text(
      '$price$suffix',
      style: AppTextStyle.titleMedium.copyWith(
        color: c.fg,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _PremiumActiveCard extends StatelessWidget {
  const _PremiumActiveCard({required this.c, required this.onClose});
  final AppColorScheme c;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassContainer(
          cardRadius: AppBorderRadius.md,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.md,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppPalette.seed,
                size: 20,
              ),
              const Gap(AppSpacing.sm),
              Text(
                'Premium 有効中',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.fg,
                ),
              ),
            ],
          ),
        ),
        const Gap(AppSpacing.md),
        PrimaryButton(label: '次へ', onPressed: onClose),
      ],
    );
  }
}

class _PremiumSmallLink extends StatelessWidget {
  const _PremiumSmallLink({
    required this.label,
    required this.onTap,
    required this.c,
  });
  final String label;
  final VoidCallback onTap;
  final AppColorScheme c;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: c.fgShade300)),
    );
  }
}
