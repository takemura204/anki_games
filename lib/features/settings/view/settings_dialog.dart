import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/noir_mind/view_model/noir_mind_view_model.dart';
import 'package:mono_games/features/settings/view_model/settings_view_model.dart';
import 'package:mono_games/i18n/translations.g.dart';
import 'package:url_launcher/url_launcher.dart';

// プレースホルダー URL（公開時に差し替えること）
const _termsUrl = 'https://example.com/terms';
const _privacyUrl = 'https://example.com/privacy';
const _contactUrl = 'https://example.com/contact';

/// ホーム画面から設定ダイアログを表示する。
void showHomeSettingsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => const _SettingsDialog(isGameScreen: false),
  );
}

/// ゲーム画面から設定ダイアログを表示する。
void showGameSettingsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => const _SettingsDialog(isGameScreen: true),
  );
}

class _SettingsDialog extends ConsumerWidget {
  const _SettingsDialog({required this.isGameScreen});

  final bool isGameScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(
        t.settings.title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // サウンド
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                t.settings.sound,
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              value: settings.soundEnabled,
              onChanged: (bool _) => notifier.toggleSound(),
            ),
            // バイブレーション
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                t.settings.vibration,
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              value: settings.vibrationEnabled,
              onChanged: (bool _) => notifier.toggleVibration(),
            ),
            Divider(color: colorScheme.outlineVariant),
            // ホーム画面専用: 利用規約・プライバシーポリシー・お問い合わせ
            if (!isGameScreen) ...[
              _LinkTile(label: t.settings.terms, url: _termsUrl),
              _LinkTile(label: t.settings.privacy, url: _privacyUrl),
              _LinkTile(label: t.settings.contact, url: _contactUrl),
            ],
            // ゲーム画面専用: ホームへ戻る・リスタート
            if (isGameScreen) ...[
              _ActionTile(
                icon: Icons.home_rounded,
                label: t.settings.home,
                onTap: () {
                  Navigator.of(context)
                    ..pop()
                    ..pop();
                },
              ),
              _ActionTile(
                icon: Icons.refresh_rounded,
                label: t.settings.restart,
                onTap: () {
                  Navigator.of(context).pop();
                  final vm = ref.read(noirMindViewModelProvider);
                  final vmNotifier =
                      ref.read(noirMindViewModelProvider.notifier);
                  if (vm.isQuestMode) {
                    vmNotifier.retryQuestLevel();
                  } else {
                    vmNotifier.resetGame();
                  }
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            t.common.ok,
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontFamily: 'Poppins')),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.inAppWebView,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(label, style: const TextStyle(fontFamily: 'Poppins')),
      onTap: onTap,
    );
  }
}
