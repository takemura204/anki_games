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

enum _Plan { monthly, lifetime }

class PaywallSheet extends HookConsumerWidget {
  const PaywallSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium =
        ref.watch(premiumViewModelProvider).asData?.value.isPremium ?? false;
    final monthlyPriceAsync = ref.watch(monthlyPriceProvider);
    final lifetimePriceAsync = ref.watch(lifetimePriceProvider);
    final expirationAsync = ref.watch(premiumExpirationDateProvider);
    final isLoading = useState(false);
    final selectedPlan = useState(_Plan.monthly);

    final c = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          gradient: c.bgGradient,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: c.border1)),
        ),
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalHandle(),
            const Gap(AppSpacing.lg),
            _Header(c: c, colorScheme: colorScheme),
            const Gap(AppSpacing.lg),
            if (isPremium)
              _ActiveContent(
                c: c,
                colorScheme: colorScheme,
                expirationAsync: expirationAsync,
                onClose: () => Navigator.of(context).pop(),
              )
            else ...[
              _FeatureList(c: c),
              const Gap(AppSpacing.lg),
              _PlanSelector(
                c: c,
                selectedPlan: selectedPlan.value,
                monthlyPriceAsync: monthlyPriceAsync,
                lifetimePriceAsync: lifetimePriceAsync,
                onSelect: (plan) => selectedPlan.value = plan,
              ),

              const Gap(AppSpacing.lg),
              _CTASection(
                c: c,
                selectedPlan: selectedPlan.value,
                monthlyPriceAsync: monthlyPriceAsync,
                lifetimePriceAsync: lifetimePriceAsync,
                isLoading: isLoading,
                bottomPadding: bottomPadding,
                onPurchase: selectedPlan.value == _Plan.monthly
                    ? () => _onPurchaseMonthly(context, ref, isLoading)
                    : () => _onPurchaseLifetime(context, ref, isLoading),
                onRestore: () => _onRestore(context, ref, isLoading),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onPurchaseMonthly(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isLoading,
  ) async {
    if (kDebugMode) {
      ref.read(premiumViewModelProvider.notifier).debugSetPremium();
      if (context.mounted) Navigator.of(context).pop();
      return;
    }
    isLoading.value = true;
    try {
      await ref.read(premiumViewModelProvider.notifier).purchase();
      final isPremium =
          ref.read(premiumViewModelProvider).asData?.value.isPremium ?? false;
      if (context.mounted && isPremium) Navigator.of(context).pop();
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.premium.errorPurchaseFailed)));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _onPurchaseLifetime(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isLoading,
  ) async {
    if (kDebugMode) {
      ref.read(premiumViewModelProvider.notifier).debugSetPremium();
      if (context.mounted) Navigator.of(context).pop();
      return;
    }
    isLoading.value = true;
    try {
      await ref.read(premiumViewModelProvider.notifier).purchaseLifetime();
      final isPremium =
          ref.read(premiumViewModelProvider).asData?.value.isPremium ?? false;
      if (context.mounted && isPremium) Navigator.of(context).pop();
    } on Exception catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.premium.errorPurchaseFailed)));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.premium.errorRestoreFailed)));
      }
    } finally {
      isLoading.value = false;
    }
  }
}
