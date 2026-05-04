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
import 'package:core/config/styles/app_icons.dart';
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
part 'widgets/menu_item.dart';
part 'widgets/divider.dart';
part 'widgets/title.dart';

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  children: [
                    const Gap(AppSpacing.sm),
                    _Title(title: 'アカウント'),
                    GlassContainer(
                      cardRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        children: [
                          _ActionMenuItem(
                            icon: isPremium
                                ? Icons.workspace_premium_rounded
                                : Icons.workspace_premium_outlined,
                            label: isPremium
                                ? t.premium.activeBadge
                                : t.premium.title,
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
                          if (kDebugMode) ...[
                            _Divider(),
                            _ActionMenuItem(
                              icon: Icons.developer_mode_rounded,
                              label: t.premium.devToggle,
                              onTap: () => ref
                                  .read(premiumViewModelProvider.notifier)
                                  .toggleMockPremium(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    _Title(title: 'カスタム'),
                    GlassContainer(
                      cardRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        children: [
                          _ToggleMenuItem(
                            icon: Icons.vibration_rounded,
                            label: t.settings.vibration,
                            value: settings.vibrationEnabled,
                            onChanged: (_) => notifier.toggleVibration(),
                          ),
                          _Divider(),
                          _SegmentedMenuItem(),
                        ],
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    _Title(title: 'サポート'),
                    GlassContainer(
                      cardRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        children: [
                          _LinkMenuItem(
                            icon: Icons.mail_outline_rounded,
                            label: 'ご意見・お問い合わせ',
                            url: AppUrls.contact,
                          ),
                        ],
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    _Title(title: 'その他'),
                    GlassContainer(
                      cardRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        children: [
                          _LinkMenuItem(
                            icon: Icons.description_outlined,
                            label: t.settings.terms,
                            url: AppUrls.termsOfService,
                          ),
                          _Divider(),
                          _LinkMenuItem(
                            icon: Icons.privacy_tip_outlined,
                            label: t.settings.privacy,
                            url: AppUrls.privacyPolicy,
                          ),
                        ],
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    GlassContainer(
                      cardRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: _DeleteDataMenuItem(),
                    ),
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
