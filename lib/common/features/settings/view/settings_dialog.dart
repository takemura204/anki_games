import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:anki_games/common/config/styles/app_text_style.dart';
import 'package:anki_games/common/config/extensions/context_extension.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:anki_games/apps/block_puzzle/features/block_puzzle/view_model/theme_view_model.dart';
import 'package:anki_games/common/features/purchase/view_model/premium_view_model.dart';
import 'package:anki_games/common/features/quiz/view_model/quiz_view_model.dart';
import 'package:anki_games/common/features/settings/view_model/settings_view_model.dart';
import 'package:anki_games/common/until/router/modal_sheet_router.dart';
import 'package:anki_games/common/config/constants/app_urls.dart';
import 'package:anki_games/common/i18n/translations.g.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({required this.isGameScreen, super.key});

  final bool isGameScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);
    final currentTheme = ref.watch(themeViewModelProvider);
    final isPremium = ref.watch(
      premiumViewModelProvider.select(
        (AsyncValue<PremiumState> s) => s.valueOrNull?.isPremium ?? false,
      ),
    );
    final colorScheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t.settings.title.toUpperCase(),
            style: AppTextStyle.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _ToggleRow(
            icon: Icons.volume_up_rounded,
            label: t.settings.sound,
            value: settings.soundEnabled,
            onChanged: (_) => notifier.toggleSound(),
          ),
          _ToggleRow(
            icon: Icons.vibration_rounded,
            label: t.settings.vibration,
            value: settings.vibrationEnabled,
            onChanged: (_) => notifier.toggleVibration(),
          ),
          _ToggleRow(
            icon: Icons.record_voice_over_rounded,
            label: t.settings.tts,
            value: settings.ttsEnabled,
            onChanged: (_) => notifier.toggleTts(),
          ),
          const _SheetDivider(),
          _ActionRow(
            icon: Icons.palette_outlined,
            label: '${currentTheme.icon}  ${currentTheme.name}',
            onTap: () {
              Navigator.of(context).pop();
              ref.read(modalSheetRouterProvider).showThemeSelector();
            },
          ),
          if (isGameScreen) ...[
            const _SheetDivider(),
            _ActionRow(
              icon: Icons.home_rounded,
              label: t.settings.home,
              onTap: () => notifier.goHome(),
            ),
            _ActionRow(
              icon: Icons.refresh_rounded,
              label: t.settings.restart,
              onTap: () async {
                Navigator.of(context).pop();
                final vm = ref.read(blockPuzzleViewModelProvider);
                final vmNotifier =
                    ref.read(blockPuzzleViewModelProvider.notifier);
                if (vm.isQuizMode) {
                  await vmNotifier.restartCurrentQuizMode();
                  ref.read(quizViewModelProvider.notifier).resetSession();
                } else {
                  vmNotifier.resetGame();
                }
              },
            ),
          ],
          if (!isGameScreen) ...[
            const _SheetDivider(),
            _ActionRow(
              icon: isPremium
                  ? Icons.workspace_premium_rounded
                  : Icons.workspace_premium_outlined,
              label: isPremium ? t.premium.activeBadge : t.premium.title,
              onTap: () => ref.read(modalSheetRouterProvider).showPaywall(),
            ),
            if (kDebugMode)
              _ActionRow(
                icon: Icons.developer_mode_rounded,
                label: t.premium.devToggle,
                onTap: () => ref
                    .read(premiumViewModelProvider.notifier)
                    .toggleMockPremium(),
              ),
            const _SheetDivider(),
            _LinkRow(
              icon: Icons.description_outlined,
              label: t.settings.terms,
              url: AppUrls.termsOfService,
            ),
            _LinkRow(
              icon: Icons.privacy_tip_outlined,
              label: t.settings.privacy,
              url: AppUrls.privacyPolicy,
            ),
            _LinkRow(
              icon: Icons.mail_outline_rounded,
              label: t.settings.contact,
              url: AppUrls.contact,
            ),
            const _SheetDivider(),
            const _DeleteLearningDataRow(),
          ],
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
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
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyle.bodyMedium.copyWith(color: colorScheme.onSurface),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colorScheme.primary,
            activeTrackColor: colorScheme.primary.withValues(alpha: 0.2),
            inactiveThumbColor: colorScheme.onSurface.withValues(alpha: 0.3),
            inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyle.bodyMedium.copyWith(color: colorScheme.onSurface),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.inAppWebView,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyle.bodyMedium.copyWith(color: colorScheme.onSurface),
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetDivider extends StatelessWidget {
  const _SheetDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: context.colorScheme.onSurface.withValues(alpha: 0.1),
      height: 16,
    );
  }
}

class _DeleteLearningDataRow extends ConsumerWidget {
  const _DeleteLearningDataRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => ref
          .read(settingsViewModelProvider.notifier)
          .onDeleteLearningData(),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: Colors.red,
            ),
            const SizedBox(width: 12),
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
}
