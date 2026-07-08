import 'dart:ui';

import 'package:core/components/admob_glass.dart';
import 'package:core/components/app_bottom_sheet.dart';
import 'package:core/components/glass_widget.dart';
import 'package:core/components/modal_handle.dart';
import 'package:core/config/ads/ad_config.dart';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/constants/app_urls.dart';
import 'package:core/config/extensions/context_extension.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_icons.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:core/features/admob/admob_interstitial.dart';
import 'package:core/features/exam_quiz/auth/auth_user_provider.dart';
import 'package:core/features/exam_quiz/backup/view_model/backup_view_model.dart';
import 'package:core/features/exam_quiz/notification/model/notification_settings.dart';
import 'package:core/features/exam_quiz/notification/service/notification_service.dart';
import 'package:core/features/exam_quiz/notification/view_model/notification_view_model.dart';
import 'package:core/features/exam_quiz/onboarding/view_model/onboarding_view_model.dart';
import 'package:core/features/exam_quiz/profile/view/profile_page.dart';
import 'package:core/features/exam_quiz/profile/view_model/profile_view_model.dart';
import 'package:core/features/exam_quiz/purchase/repository/local_sale_promo_repository.dart';
import 'package:core/features/exam_quiz/purchase/view/paywall_sheet.dart';
import 'package:core/features/exam_quiz/quiz/repository/motivation_last_shown_repository.dart';
import 'package:core/features/purchase/model/pricing.dart';
import 'package:core/features/purchase/view_model/premium_view_model.dart';
import 'package:core/features/settings/view_model/settings_view_model.dart';
import 'package:core/i18n/translations.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

part 'widgets/divider.dart';
part 'widgets/header.dart';
part 'widgets/menu_item.dart';
part 'widgets/title.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      height: context.height * 0.85,
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Navigator(
            onGenerateRoute: (_) =>
                MaterialPageRoute<void>(builder: (_) => const _SettingsPage()),
          ),
        ),
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

    final isSync = ref.watch(isSyncEnabledProvider);
    final backupAsync = ref.watch(backupViewModelProvider);
    final notificationAsync = ref.watch(notificationViewModelProvider);
    final lastBackupAt = useState<DateTime?>(null);
    final packageInfo = useState<PackageInfo?>(null);
    final permissionGranted = useState<bool?>(null);
    final version = packageInfo.value?.version ?? '-';

    useEffect(() {
      PackageInfo.fromPlatform().then((v) => packageInfo.value = v);
      ref
          .read(backupViewModelProvider.notifier)
          .lastBackupAt()
          .then((v) => lastBackupAt.value = v);
      NotificationService.instance.isPermissionGranted().then(
        (v) => permissionGranted.value = v,
      );

      final observer = _PermissionObserver(
        onResumed: () async {
          final nowGranted = await NotificationService.instance
              .isPermissionGranted();
          if (permissionGranted.value != true && nowGranted) {
            permissionGranted.value = true;
            final s = ref.read(notificationViewModelProvider).asData?.value;
            if (s != null && !s.enabled) {
              await ref
                  .read(notificationViewModelProvider.notifier)
                  .saveSettings(
                    s.copyWith(
                      enabled: true,
                      hour: s.hour ?? 8,
                      minute: s.minute ?? 0,
                    ),
                  );
            }
          } else {
            permissionGranted.value = nowGranted;
          }
        },
      );
      WidgetsBinding.instance.addObserver(observer);
      return () => WidgetsBinding.instance.removeObserver(observer);
    }, const []);

    ref.listen<AsyncValue<void>>(backupViewModelProvider, (prev, next) {
      if (prev?.isLoading == true && !next.isLoading) {
        final messenger = ScaffoldMessenger.of(context);
        if (next.hasError) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('処理に失敗しました'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('完了しました'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref
              .read(backupViewModelProvider.notifier)
              .lastBackupAt()
              .then((v) => lastBackupAt.value = v);
        }
      }
    });

    final notifSettings = notificationAsync.asData?.value;
    final notifValueText = _notificationValueText(
      notifSettings,
      permissionGranted.value,
    );

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
              const _Title(title: 'アカウント'),
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
                    const _Divider(),
                    _MenuItem(
                      icon: isPremium
                          ? Icons.workspace_premium_rounded
                          : Icons.workspace_premium_outlined,
                      label: 'プレミアム',
                      valueText: isPremium ? '加入中' : '未登録',
                      onTap: () async {
                        if (!context.mounted) return;
                        await showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          constraints: const BoxConstraints(),
                          builder: (_) => const PaywallSheet(),
                        );
                      },
                    ),
                    if (isSync) ...[
                      const _Divider(),
                      _MenuItem(
                        icon: Icons.backup_outlined,
                        label: 'バックアップ',
                        valueText: backupAsync.isLoading
                            ? '処理中...'
                            : _formatDate(lastBackupAt.value),
                        trailingIcon: backupAsync.isLoading
                            ? null
                            : Icons.chevron_right_rounded,
                        onTap: backupAsync.isLoading
                            ? () {}
                            : () => _confirmUpload(context, ref),
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(AppSpacing.md),
              const _Title(title: 'カスタム'),
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
                    const _Divider(),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: '学習リマインダー',
                      valueText: notifValueText,
                      onTap: () async {
                        final granted = await NotificationService.instance
                            .requestPermission(context);
                        if (!context.mounted) return;
                        permissionGranted.value = granted;
                        if (!granted) return;
                        if (notifSettings == null || !notifSettings.enabled) {
                          await _autoEnableNotification(
                            notifSettings,
                            ref.read(notificationViewModelProvider.notifier),
                          );
                        }
                        if (!context.mounted) return;
                        await showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          constraints: const BoxConstraints(),
                          builder: (_) => const _NotificationSheet(),
                        );
                        if (context.mounted) {
                          NotificationService.instance
                              .isPermissionGranted()
                              .then((v) => permissionGranted.value = v)
                              .ignore();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.md),
              const _Title(title: 'サポート'),
              GlassContainer(
                cardRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  children: [
                    const _LinkMenuItem(
                      icon: Icons.mail_outline_rounded,
                      label: 'ご意見・お問い合わせ',
                      url: AppUrls.contact,
                    ),
                    const _Divider(),
                    const _LinkMenuItem(
                      icon: Icons.star_outline_rounded,
                      label: 'レビューで応援',
                      url: AppUrls.appStoreReviewUrl,
                      launchMode: LaunchMode.externalApplication,
                    ),
                    const _Divider(),
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
              const AdmobNativeGlass(),
              const Gap(AppSpacing.md),
              const _Title(title: 'その他'),
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
                    const _Divider(),
                    _LinkMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      label: t.settings.privacy,
                      url: AppUrls.privacyPolicy,
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.md),
              if (kDebugMode) ...[
                const _Title(title: '🛠 DEBUG'),
                GlassContainer(
                  cardRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'インタースティシャル広告テスト',
                        trailingIcon: null,
                        onTap: () {
                          AdmobInterstitial(
                            ref.read(adConfigProvider),
                          ).loadAndShow();
                          debugPrint('[AdInterstitial][DEBUG] 手動テスト呼び出し');
                        },
                      ),

                      const _Divider(),
                      _MenuItem(
                        icon: Icons.school_outlined,
                        label: 'チュートリアルをリセット',
                        trailingIcon: null,
                        onTap: () async {
                          await ref
                              .read(onboardingViewModelProvider.notifier)
                              .reset();
                          if (context.mounted) {
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pop();
                          }
                        },
                      ),
                      const _Divider(),
                      _MenuItem(
                        icon: Icons.notifications_active_outlined,
                        label: '通知を送信',
                        trailingIcon: null,
                        onTap: () async {
                          final granted = await NotificationService.instance
                              .requestPermission(context);
                          if (!context.mounted) return;
                          if (!granted) return;
                          await NotificationService.instance
                              .showTestNotification();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('テスト通知を送信しました'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const _Divider(),
                      _MenuItem(
                        icon: Icons.price_check_outlined,
                        label: '価格デバッグ',
                        trailingIcon: null,
                        onTap: () async {
                          final pricing = await ref.read(
                            pricingProvider.future,
                          );
                          if (!context.mounted) return;
                          await showDialog<void>(
                            context: context,
                            builder: (_) =>
                                _PricingDebugDialog(pricing: pricing),
                          );
                        },
                      ),
                      const _Divider(),
                      _MenuItem(
                        icon: Icons.auto_awesome_outlined,
                        label: 'モチベーションカードをリセット',
                        trailingIcon: null,
                        onTap: () async {
                          await MotivationLastShownRepository().reset();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'リセット完了。次回アプリ起動時にモチベーションカードが表示されます。',
                              ),
                            ),
                          );
                        },
                      ),
                      const _Divider(),
                      _MenuItem(
                        icon: Icons.redeem_outlined,
                        label: 'セールバナーを確認',
                        trailingIcon: null,
                        onTap: () async {
                          await ref.read(salePromoRepositoryProvider).restart();
                          if (!context.mounted) return;
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const PaywallSheet(saleMode: true),
                          );
                        },
                      ),
                      const _Divider(),
                      _MenuItem(
                        icon: Icons.restart_alt_outlined,
                        label: 'セール本日表示済みフラグをリセット',
                        trailingIcon: null,
                        onTap: () async {
                          await ref.read(salePromoRepositoryProvider).restart();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'リセット完了。次回クイズ結果画面（累計2セット目以降）'
                                'でセールが表示されます。',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Gap(AppSpacing.md),
              ],
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

  Future<void> _confirmUpload(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('バックアップ'),
        content: const Text(
          'クラウドのデータを現在のデータで上書きします。よろしいですか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('バックアップする'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(backupViewModelProvider.notifier).upload().ignore();
    }
  }
}

class _PermissionObserver extends WidgetsBindingObserver {
  _PermissionObserver({required this.onResumed});

  final Future<void> Function() onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}

Future<void> _autoEnableNotification(
  NotificationSettings? settings,
  NotificationViewModel notifier,
) async {
  await notifier.saveSettings(
    NotificationSettings(
      enabled: true,
      hour: settings?.hour ?? 8,
      minute: settings?.minute ?? 0,
      streakReminderEnabled: settings?.streakReminderEnabled ?? true,
    ),
  );
}

String _notificationValueText(
  NotificationSettings? settings,
  bool? permissionGranted,
) {
  if (permissionGranted == false) return '許可しない';
  if (settings == null || !settings.enabled) return 'オフ';
  final hour = settings.hour;
  final minute = settings.minute;
  if (hour == null || minute == null) return 'オフ';
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

String? _formatDate(DateTime? dt) {
  if (dt == null) return null;
  final y = dt.year;
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '最終: $y/$m/$d';
}

class _NotificationSheet extends HookConsumerWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.appColors;
    final notificationAsync = ref.watch(notificationViewModelProvider);
    final notificationNotifier = ref.read(
      notificationViewModelProvider.notifier,
    );
    final settings = notificationAsync.asData?.value;
    final isEnabled = settings?.enabled ?? false;
    final hour = settings?.hour;
    final minute = settings?.minute;
    final timeText = (hour != null && minute != null)
        ? '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'
        : null;

    return AppBottomSheet(
      height: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModalHandle(),
          const Gap(AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              '学習リマインダー',
              style: AppTextStyle.titleMedium.copyWith(
                color: c.fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Gap(AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: GlassContainer(
              cardRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                children: [
                  _ToggleMenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'リマインダー',
                    value: isEnabled,
                    onChanged: (v) async {
                      if (v) {
                        if (hour == null || minute == null) {
                          if (context.mounted) {
                            await _showTimePicker(
                              context,
                              initialHour: 8,
                              initialMinute: 0,
                              onConfirm: (h, m) async {
                                await notificationNotifier.saveSettings(
                                  NotificationSettings(
                                    enabled: true,
                                    hour: h,
                                    minute: m,
                                    streakReminderEnabled:
                                        settings?.streakReminderEnabled ?? true,
                                  ),
                                );
                              },
                            );
                          }
                        } else {
                          await notificationNotifier.saveSettings(
                            NotificationSettings(
                              enabled: true,
                              hour: hour,
                              minute: minute,
                              streakReminderEnabled:
                                  settings?.streakReminderEnabled ?? true,
                            ),
                          );
                        }
                      } else {
                        await notificationNotifier.disable();
                      }
                    },
                  ),
                  if (isEnabled) ...[
                    const _Divider(),
                    _MenuItem(
                      icon: Icons.access_time_rounded,
                      label: '通知時間',
                      valueText: timeText,
                      onTap: () => _showTimePicker(
                        context,
                        initialHour: hour ?? 8,
                        initialMinute: minute ?? 0,
                        onConfirm: notificationNotifier.setTime,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Gap(AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context, {
    required int initialHour,
    required int initialMinute,
    required Future<void> Function(int hour, int minute) onConfirm,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: const BoxConstraints(),
      builder: (_) => _NotificationTimePickerSheet(
        initialHour: initialHour,
        initialMinute: initialMinute,
        onConfirm: onConfirm,
      ),
    );
  }
}

class _NotificationTimePickerSheet extends StatefulWidget {
  const _NotificationTimePickerSheet({
    required this.initialHour,
    required this.initialMinute,
    required this.onConfirm,
  });

  final int initialHour;
  final int initialMinute;
  final Future<void> Function(int hour, int minute) onConfirm;

  @override
  State<_NotificationTimePickerSheet> createState() =>
      _NotificationTimePickerSheetState();
}

class _NotificationTimePickerSheetState
    extends State<_NotificationTimePickerSheet> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialHour;
    _minute = widget.initialMinute;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: c.surfaceSheet,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: c.border1)),
          ),
          padding: EdgeInsets.only(bottom: bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'キャンセル',
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: c.fgShade400,
                        ),
                      ),
                    ),
                    Text(
                      '通知時間',
                      style: AppTextStyle.titleSmall.copyWith(
                        color: c.fg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await widget.onConfirm(_hour, _minute);
                        if (!mounted) return;
                        navigator.pop();
                      },
                      child: Text(
                        '完了',
                        style: AppTextStyle.bodyMedium.copyWith(
                          color: AppPalette.seed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _hour,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => setState(() => _hour = i),
                        children: List.generate(
                          24,
                          (i) => Center(
                            child: Text(
                              i.toString().padLeft(2, '0'),
                              style: AppTextStyle.titleMedium.copyWith(
                                color: c.fg,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      ':',
                      style: AppTextStyle.titleLarge.copyWith(color: c.fg),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: _minute ~/ 5,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) =>
                            setState(() => _minute = i * 5),
                        children: List.generate(
                          12,
                          (i) => Center(
                            child: Text(
                              (i * 5).toString().padLeft(2, '0'),
                              style: AppTextStyle.titleMedium.copyWith(
                                color: c.fg,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricingDebugDialog extends StatelessWidget {
  const _PricingDebugDialog({required this.pricing});

  final Pricing pricing;

  static String _fmt(String? v) => v ?? '(null)';

  List<_DiagRow> _diagRows() {
    final rows = <_DiagRow>[];

    if (!pricing.saleMonthlyFound) {
      rows.add(
        const _DiagRow(
          icon: '🔴',
          text:
              '月額: premium_sale Offering にパッケージなし\n'
              '→ RevenueCat の Offering 設定を確認してください',
        ),
      );
    } else if (pricing.monthlyDiscountPercent == null) {
      rows.add(
        const _DiagRow(
          icon: '⚠️',
          text:
              '月額: Offering は取得できたが価格が通常と同額\n'
              '→ App Store Connect の商品価格を確認してください',
        ),
      );
    } else {
      rows.add(
        _DiagRow(
          icon: '✅',
          text: '月額: 割引あり (${pricing.monthlyDiscountPercent}% OFF)',
        ),
      );
    }

    if (!pricing.saleLifetimeFound) {
      rows.add(
        const _DiagRow(
          icon: '🔴',
          text:
              '買い切り: premium_sale Offering にパッケージなし\n'
              '→ RevenueCat の Offering 設定を確認してください',
        ),
      );
    } else if (pricing.lifetimeDiscountAmount == null) {
      rows.add(
        const _DiagRow(
          icon: '⚠️',
          text:
              '買い切り: Offering は取得できたが価格が通常と同額\n'
              '→ App Store Connect の商品価格を確認してください',
        ),
      );
    } else {
      rows.add(
        _DiagRow(
          icon: '✅',
          text: '買い切り: 割引あり (${pricing.lifetimeDiscountAmount})',
        ),
      );
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('価格デバッグ'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '── Offering 取得状況 ──',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '月額パッケージ: ${pricing.saleMonthlyFound ? "✅ 取得済み" : "🔴 未取得"}',
            ),
            Text(
              '買い切りパッケージ: ${pricing.saleLifetimeFound ? "✅ 取得済み" : "🔴 未取得"}',
            ),
            const SizedBox(height: 12),
            const Text(
              '── 月額 ──',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('通常価格: ${_fmt(pricing.monthlyNormal)}'),
            Text('セール価格: ${_fmt(pricing.monthlySale)}'),
            Text('1日あたり: ${_fmt(pricing.monthlySalePerDay)}'),
            Text(
              '割引率: ${pricing.monthlyDiscountPercent != null ? '${pricing.monthlyDiscountPercent}% OFF' : '(なし)'}',
            ),
            const SizedBox(height: 12),
            const Text(
              '── 買い切り ──',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('通常価格: ${_fmt(pricing.lifetimeNormal)}'),
            Text('セール価格: ${_fmt(pricing.lifetimeSale)}'),
            Text('割引額: ${_fmt(pricing.lifetimeDiscountAmount)}'),
            Text(
              '通常 raw price: ${pricing.debugLifetimeNormalRawPrice ?? "(null)"}',
            ),
            Text(
              'セール raw price: ${pricing.debugLifetimeSaleRawPrice ?? "(null)"}',
            ),
            Text(
              '通常 store product ID: ${_fmt(pricing.debugLifetimeNormalProductId)}',
            ),
            Text(
              'セール store product ID: ${_fmt(pricing.debugLifetimeSaleProductId)}',
            ),
            const SizedBox(height: 16),
            const Text(
              '── 診断 ──',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ..._diagRows().map(
              (r) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${r.icon} ${r.text}'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '※ 詳細は Xcode コンソールの [RevenueCat] ログを確認\n'
              '  "premium_sale offering found:" の行に注目してください。',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

class _DiagRow {
  const _DiagRow({required this.icon, required this.text});
  final String icon;
  final String text;
}
