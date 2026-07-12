import 'dart:io';

import 'package:core/components/buttons.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/components/modal_handle.dart';
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
import 'package:core/features/purchase/model/plan_type.dart';
import 'package:core/features/purchase/model/pricing.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

part 'widgets/header.dart';
part 'widgets/feature_list.dart';
part 'widgets/plan_selector.dart';
part 'widgets/cta_section.dart';
part 'widgets/active_content.dart';

class PaywallSheet extends HookConsumerWidget {
  const PaywallSheet({super.key, this.saleMode = false});

  /// true のとき premium_sale Offering の価格で購入し、セールバナーを表示する。
  final bool saleMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium =
        ref.watch(premiumViewModelProvider).asData?.value.isPremium ?? false;
    final pricingAsync = ref.watch(pricingProvider);
    final expirationAsync = ref.watch(premiumExpirationDateProvider);
    final recommendedPlan =
        ref.watch(recommendedPlanProvider).asData?.value ?? PlanType.monthly;
    final isLoading = useState(false);
    final selectedPlan = useState(recommendedPlan);
    final animCtrl = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );
    final anim = useMemoized(() => OnboardingPageAnim.from(animCtrl));
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => animCtrl.forward());
      return null;
    }, const []);
    final c = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          gradient: c.bgGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: c.border1)),
        ),
        // シートの最大高を画面の 92% に制限し、overflow を防ぐ
        constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ハンドルは固定（スクロール対象外）
            const ModalHandle(),
            // コンテンツはスクロール可能
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  bottomPadding,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPremium)
                      _ActiveContent(
                        c: c,
                        colorScheme: colorScheme,
                        expirationAsync: expirationAsync,
                        onClose: () => Navigator.of(context).pop(),
                      )
                    else ...[
                      OnboardingFadeSlide(
                        fade: anim.topFade,
                        slide: anim.topSlide,
                        child: _Header(c: c, colorScheme: colorScheme),
                      ),
                      const Gap(AppSpacing.lg),
                      OnboardingFadeSlide(
                        fade: anim.bottomFade,
                        slide: anim.bottomSlide,
                        child: Column(
                          children: [
                            _FeatureList(c: c),
                            const Gap(AppSpacing.lg),
                            _PlanSelector(
                              c: c,
                              selectedPlan: selectedPlan.value,
                              pricingAsync: pricingAsync,
                              saleMode: saleMode,
                              recommendedPlan: recommendedPlan,
                              onSelect: (plan) => selectedPlan.value = plan,
                            ),
                            const Gap(AppSpacing.lg),
                            _CTASection(
                              c: c,
                              selectedPlan: selectedPlan.value,
                              pricingAsync: pricingAsync,
                              saleMode: saleMode,
                              isLoading: isLoading,
                              onPurchase: () => _onPurchase(
                                context,
                                ref,
                                isLoading,
                                selectedPlan.value,
                              ),
                              onRestore: () =>
                                  _onRestore(context, ref, isLoading),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPurchase(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isLoading,
    PlanType plan,
  ) async {
    if (kDebugMode) {
      ref.read(premiumViewModelProvider.notifier).debugSetPremium();
      return;
    }
    isLoading.value = true;
    try {
      await ref
          .read(premiumViewModelProvider.notifier)
          .purchasePlan(plan, sale: saleMode);
      final isPremium =
          ref.read(premiumViewModelProvider).asData?.value.isPremium ?? false;
      if (context.mounted && isPremium) Navigator.of(context).pop();
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.premium.errorPurchaseFailed)),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _onRestore(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    try {
      await ref.read(premiumViewModelProvider.notifier).restore();
      final isPremium =
          ref.read(premiumViewModelProvider).asData?.value.isPremium ?? false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPremium ? t.premium.restoreSuccess : t.premium.restoreNotFound,
            ),
          ),
        );
        if (isPremium) Navigator.of(context).pop();
      }
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.premium.errorRestoreFailed)),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}
