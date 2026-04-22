import 'dart:ui';

import 'package:app_it_pass/components/glass_widget.dart';
import 'package:app_it_pass/components/modal_handle.dart';
import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:app_it_pass/features/learning/providers/it_pass_learning_stats_provider.dart';
import 'package:app_it_pass/features/settings/view_model/theme_mode_view_model.dart';
import 'package:app_it_pass/features/learning/repository/local_learning_history_repository.dart';
import 'package:app_it_pass/features/quiz/view_model/quiz_view_model.dart';
import 'package:core/config/constants/app_urls.dart';
import 'package:core/config/extensions/context_extension.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/purchase/view/paywall_bottom_sheet.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/features/settings/view_model/settings_view_model.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

part 'widgets/header.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final settings = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);
    final isPremium = ref.watch(
      premiumViewModelProvider.select(
        (AsyncValue<PremiumState> s) => s.asData?.value.isPremium ?? false,
      ),
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: context.height * 0.85,
          decoration: BoxDecoration(
            color: c.surfaceSheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: c.border1),
              left: BorderSide(color: c.border1),
              right: BorderSide(color: c.border1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ModalHandle(),
              _Header(onClose: () => Navigator.of(context).pop(false)),
              const Gap(AppSpacing.sm),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    const Gap(AppSpacing.sm),
                    _ItPassToggleRow(
                      icon: Icons.vibration_rounded,
                      label: t.settings.vibration,
                      value: settings.vibrationEnabled,
                      onChanged: (_) => notifier.toggleVibration(),
                    ),
                    _ItPassThemeSelectorRow(),
                    _ItPassDivider(color: c.fgShade50),
                    _ItPassActionRow(
                      icon: isPremium
                          ? Icons.workspace_premium_rounded
                          : Icons.workspace_premium_outlined,
                      label:
                          isPremium ? t.premium.activeBadge : t.premium.title,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => const PaywallSheet(),
                        );
                      },
                    ),
                    if (kDebugMode)
                      _ItPassActionRow(
                        icon: Icons.developer_mode_rounded,
                        label: t.premium.devToggle,
                        onTap: () => ref
                            .read(premiumViewModelProvider.notifier)
                            .toggleMockPremium(),
                      ),
                    _ItPassDivider(color: c.fgShade50),
                    _ItPassLinkRow(
                      icon: Icons.description_outlined,
                      label: t.settings.terms,
                      url: AppUrls.termsOfService,
                    ),
                    _ItPassLinkRow(
                      icon: Icons.privacy_tip_outlined,
                      label: t.settings.privacy,
                      url: AppUrls.privacyPolicy,
                    ),
                    _ItPassLinkRow(
                      icon: Icons.mail_outline_rounded,
                      label: t.settings.contact,
                      url: AppUrls.contact,
                    ),
                    _ItPassDivider(color: c.fgShade50),
                    _ItPassDeleteLearningDataRow(),
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

// ── Toggle row ──────────────────────────────────────────────────────────────

class _ItPassToggleRow extends StatelessWidget {
  const _ItPassToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.fgShade400),
          const Gap(AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTextStyle.bodyMedium.copyWith(color: c.fg),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.itPassSeed,
            activeTrackColor: AppColors.itPassSeed.withValues(alpha: 0.25),
            inactiveThumbColor: c.fgShade200,
            inactiveTrackColor: c.surface2,
          ),
        ],
      ),
    );
  }
}

// ── Action row ──────────────────────────────────────────────────────────────

class _ItPassActionRow extends StatelessWidget {
  const _ItPassActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.fgShade400),
            const Gap(AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyle.bodyMedium.copyWith(color: c.fg),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.fgShade200),
          ],
        ),
      ),
    );
  }
}

// ── Link row ────────────────────────────────────────────────────────────────

class _ItPassLinkRow extends StatelessWidget {
  const _ItPassLinkRow({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView),
      borderRadius: AppBorderRadius.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.fgShade400),
            const Gap(AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyle.bodyMedium.copyWith(color: c.fg),
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 18, color: c.fgShade200),
          ],
        ),
      ),
    );
  }
}

// ── Theme selector ───────────────────────────────────────────────────────────

class _ItPassThemeSelectorRow extends ConsumerWidget {
  const _ItPassThemeSelectorRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final mode = ref.watch(themeModeViewModelProvider);
    final notifier = ref.read(themeModeViewModelProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.palette_outlined, size: 20, color: c.fgShade400),
          const Gap(AppSpacing.md),
          Expanded(
            child: Text(
              'テーマ',
              style: AppTextStyle.bodyMedium.copyWith(color: c.fg),
            ),
          ),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded, size: 16),
                tooltip: 'システム',
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: 16),
                tooltip: 'ライト',
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: 16),
                tooltip: 'ダーク',
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => notifier.setMode(s.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: WidgetStatePropertyAll(
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.itPassSeed;
                }
                return c.surface1;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return c.fgShade400;
              }),
              side: WidgetStatePropertyAll(BorderSide(color: c.border1)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Divider ─────────────────────────────────────────────────────────────────

class _ItPassDivider extends StatelessWidget {
  const _ItPassDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Divider(color: color, height: AppSpacing.lg);
  }
}

// ── Delete learning data ─────────────────────────────────────────────────────

class _ItPassDeleteLearningDataRow extends ConsumerWidget {
  const _ItPassDeleteLearningDataRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _onTap(context, ref),
      borderRadius: AppBorderRadius.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Colors.red,
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Text(
                t.settings.deleteLearningData,
                style: AppTextStyle.bodyMedium.copyWith(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.settings.deleteLearningDataConfirmTitle),
        content: Text(t.settings.deleteLearningDataConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.settings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.settings.deleteLearningDataConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    await LocalLearningHistoryRepository().deleteAll();
    ref.invalidate(itPassLearningStatsProvider);
    ref.invalidate(quizViewModelProvider);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
