import 'package:core/components/adaptive_body.dart';
import 'package:core/components/buttons.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/config/brand/it_pass_color_scheme.dart';
import 'package:core/config/constants/app_urls.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/exam_quiz/onboarding/model/onboarding_plan.dart';
import 'package:core/features/exam_quiz/onboarding/view/widgets/onboarding_page_anim.dart';
import 'package:core/features/exam_quiz/onboarding/view_model/onboarding_ui_notifier.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingPremiumPage extends ConsumerStatefulWidget {
  const OnboardingPremiumPage({
    super.key,
    required this.onPurchase,
    required this.onSkip,
  });

  final VoidCallback onPurchase;
  final VoidCallback onSkip;

  @override
  ConsumerState<OnboardingPremiumPage> createState() =>
      _OnboardingPremiumPageState();
}

class _OnboardingPremiumPageState extends ConsumerState<OnboardingPremiumPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final OnboardingPageAnim _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
    final ob = ref.watch(onboardingUiProvider);
    final notifier = ref.read(onboardingUiProvider.notifier);
    final isPremium =
        ref.watch(premiumViewModelProvider).asData?.value.isPremium ?? false;
    final monthlyPriceAsync = ref.watch(monthlyPriceProvider);
    final lifetimePriceAsync = ref.watch(lifetimePriceProvider);
    final c = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).padding.bottom;

    return AdaptiveBody(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xxxl,
          AppSpacing.md,
          bottom + AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Section 1: ヘッダー
          OnboardingFadeSlide(
            fade: _anim.topFade,
            slide: _anim.topSlide,
            child: _PremiumHeader(c: c, colorScheme: colorScheme),
          ),
          const Gap(AppSpacing.lg),
          // Section 2: プラン選択 + ボタン
          OnboardingFadeSlide(
            fade: _anim.bottomFade,
            slide: _anim.bottomSlide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isPremium)
                  _PremiumActiveCard(c: c, onClose: widget.onSkip)
                else ...[
                  _PremiumFeatureListSection(c: c),
                  const Gap(AppSpacing.lg),
                  _PremiumPlanSelectorSection(
                    c: c,
                    selectedPlan: ob.selectedPlan,
                    monthlyPriceAsync: monthlyPriceAsync,
                    lifetimePriceAsync: lifetimePriceAsync,
                    onSelect: notifier.selectPlan,
                  ),
                  const Gap(AppSpacing.lg),
                  PrimaryButton(
                    label: 'プレミアムを体験する',
                    onPressed:
                        (ob.isPurchaseLoading || monthlyPriceAsync.isLoading)
                        ? null
                        : widget.onPurchase,
                    isLoading: ob.isPurchaseLoading,
                    height: 60,
                  ),
                  const Gap(AppSpacing.sm),
                  TextButton(
                    onPressed: widget.onSkip,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    child: Text(
                      'あとにする',
                      style: AppTextStyle.bodySmall.copyWith(
                        color: c.fgShade300,
                        decoration: TextDecoration.underline,
                        decorationColor: c.fgShade300,
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PremiumSmallLink(
                        label: t.premium.restoreButton,
                        onTap: () {},
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
                          mode: LaunchMode.inAppWebView,
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
                          mode: LaunchMode.inAppWebView,
                        ),
                        c: c,
                      ),
                    ],
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
  final ItPassColorScheme c;
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
  final ItPassColorScheme c;

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
    required this.monthlyPriceAsync,
    required this.lifetimePriceAsync,
    required this.onSelect,
  });
  final ItPassColorScheme c;
  final OnboardingPlan selectedPlan;
  final AsyncValue<String?> monthlyPriceAsync;
  final AsyncValue<String?> lifetimePriceAsync;
  final void Function(OnboardingPlan) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: GlassButton(
        cardRadius: AppBorderRadius.md,
        child: Column(
          children: [
            _PlanRow(
              title: '1ヶ月プラン',
              subtitle: '毎月更新。いつでもキャンセル可能。',
              priceAsync: monthlyPriceAsync,
              isSelected: selectedPlan == OnboardingPlan.monthly,
              onTap: () => onSelect(OnboardingPlan.monthly),
              c: c,
              priceSuffix: '月',
            ),
            Divider(height: 1, indent: 14, endIndent: 14, color: c.fgShade50),
            _PlanRow(
              title: '買い切りプラン',
              subtitle: '１度切りのお支払い。無制限に利用可能。',
              priceAsync: lifetimePriceAsync,
              isSelected: selectedPlan == OnboardingPlan.lifetime,
              onTap: () => onSelect(OnboardingPlan.lifetime),
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
    required this.priceAsync,
    required this.isSelected,
    required this.onTap,
    required this.c,
    this.priceSuffix,
  });
  final String title;
  final String subtitle;
  final AsyncValue<String?> priceAsync;
  final bool isSelected;
  final VoidCallback onTap;
  final ItPassColorScheme c;
  final String? priceSuffix;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap.withHaptic(HapticType.selection),
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        decoration: BoxDecoration(
          color: isSelected
              ? ItPassColors.seed.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? ItPassColors.seed : Colors.transparent,
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
                      color: ItPassColors.seed,
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
                  Text(
                    title,
                    style: AppTextStyle.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: c.fg,
                    ),
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
            if (priceAsync.isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: c.fg),
              )
            else ...[
              Text(
                priceAsync.asData?.value ?? '---',
                style: AppTextStyle.titleMedium.copyWith(
                  color: c.fg,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (priceSuffix != null) ...[
                const Gap(AppSpacing.xs),
                Text(
                  '/$priceSuffix',
                  style: AppTextStyle.labelMedium.copyWith(color: c.fgShade400),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumActiveCard extends StatelessWidget {
  const _PremiumActiveCard({required this.c, required this.onClose});
  final ItPassColorScheme c;
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
                color: ItPassColors.seed,
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
  final ItPassColorScheme c;

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
