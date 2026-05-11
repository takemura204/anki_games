import 'package:app_it_pass/features/learning/providers/data_sync_status_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_it_pass/components/app_bottom_sheet.dart';
import 'package:app_it_pass/components/glass_widget.dart';
import 'package:app_it_pass/components/modal_handle.dart';
import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:app_it_pass/features/profile/view/modals/auth_link_modal.dart';
import 'package:app_it_pass/features/profile/view/profile_page.dart';
import 'package:app_it_pass/features/profile/view_model/profile_view_model.dart';
import 'package:core/config/constants/app_urls.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/extensions/context_extension.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/admob/admob_native.dart';
import 'package:app_it_pass/features/purchase/view/paywall_sheet.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/features/settings/view_model/settings_view_model.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
part 'widgets/header.dart';
part 'widgets/menu_item.dart';
part 'widgets/divider.dart';
part 'widgets/title.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      height: context.height * 0.85,
      child: Navigator(
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => const _SettingsPage()),
      ),
    );
  }
}

class _SettingsPage extends HookConsumerWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);
    final isPremium = ref.watch(
      premiumViewModelProvider.select(
        (AsyncValue<PremiumState> s) => s.asData?.value.isPremium ?? false,
      ),
    );
    final profileAsync = ref.watch(profileViewModelProvider);
    final userName = profileAsync.asData?.value.displayName;

    final user = FirebaseAuth.instance.currentUser;
    final isLinked = user != null && user.providerData.isNotEmpty;
    final syncStatus = ref.watch(dataSyncStatusProvider);
    final packageInfo = useState<PackageInfo?>(null);
    final version = packageInfo.value?.version ?? '-';
    useEffect(() {
      PackageInfo.fromPlatform().then((v) => packageInfo.value = v);
      return null;
    }, const []);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ModalHandle(),
        _Header(
          onClose: () => Navigator.of(context, rootNavigator: true).pop(false),
        ),
        const Gap(AppSpacing.sm),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              const Gap(AppSpacing.sm),
              _Title(title: 'アカウント'),
              GlassContainer(
                cardRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'プロフィール',
                      valueText: userName ?? '未入力',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfilePage(),
                        ),
                      ),
                    ),
                    _Divider(),
                    _MenuItem(
                      icon: isPremium
                          ? Icons.workspace_premium_rounded
                          : Icons.workspace_premium_outlined,
                      label: 'プレミアム',
                      valueText: isPremium ? '加入中' : '未登録',
                      onTap: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => const PaywallSheet(),
                        );
                      },
                    ),
                    _Divider(),
                    _MenuItem(
                      icon: Icons.sync_outlined,
                      label: 'データ同期',
                      valueText: _syncValueText(
                          isPremium: isPremium,
                          isLinked: isLinked,
                          status: syncStatus),
                      trailingIcon: (isPremium && isLinked)
                          ? null
                          : Icons.chevron_right_rounded,
                      onTap: () {
                        if (!isPremium) {
                          showModalBottomSheet<void>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => const PaywallSheet(),
                          );
                          return;
                        }
                        if (!isLinked) {
                          showModalBottomSheet<void>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => const _DataSyncAuthSheet(),
                          );
                          return;
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.md),
              _Title(title: 'カスタム'),
              GlassContainer(
                cardRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: _ToggleMenuItem(
                  icon: Icons.vibration_rounded,
                  label: t.settings.vibration,
                  value: settings.vibrationEnabled,
                  onChanged: (_) => notifier.toggleVibration(),
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
                    _Divider(),
                    _LinkMenuItem(
                      icon: Icons.star_outline_rounded,
                      label: 'レビューで応援',
                      url: AppUrls.appStoreReviewUrl,
                      launchMode: LaunchMode.externalApplication,
                    ),
                    _Divider(),
                    _MenuItem(
                      icon: Icons.share_outlined,
                      label: 'このアプリをシェア',
                      trailingIcon: null,
                      onTap: () => SharePlus.instance.share(
                        ShareParams(text: AppUrls.appStoreUrl),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.md),
              GlassContainer(
                cardRadius: AppBorderRadius.md,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: const AdmobNative(),
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
              const Gap(AppSpacing.md),
              Center(
                child: Text(
                  'App Version: $version',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: context.appColors.fgShade400,
                  ),
                ),
              ),

              const Gap(AppSpacing.md),
            ],
          ),
        ),
      ],
    );
  }
}

String _syncValueText({
  required bool isPremium,
  required bool isLinked,
  required DataSyncStatus status,
}) {
  if (!isPremium || !isLinked) return '未連携';
  return switch (status) {
    DataSyncStatus.syncing => '同期中...',
    DataSyncStatus.synced => '連携済み',
    DataSyncStatus.failed => '同期失敗',
    DataSyncStatus.idle => '連携済み',
  };
}

class _DataSyncAuthSheet extends StatelessWidget {
  const _DataSyncAuthSheet();

  @override
  Widget build(BuildContext context) {
    return const AuthLinkModal();
  }
}
