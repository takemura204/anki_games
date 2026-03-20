import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/config/constants/app_urls.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/view/modals/theme_selector_sheet.dart';
import 'package:mono_games/features/block_puzzle/view_model/block_puzzle_view_model.dart';
import 'package:mono_games/features/block_puzzle/view_model/theme_view_model.dart';
import 'package:mono_games/features/quiz/view_model/quiz_view_model.dart';
import 'package:mono_games/features/settings/view_model/settings_view_model.dart';
import 'package:mono_games/i18n/translations.g.dart';
import 'package:url_launcher/url_launcher.dart';

/// ホーム画面から設定ボトムシートを表示する。
void showHomeSettingsDialog(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _SettingsSheet(isGameScreen: false),
  );
}

/// ゲーム画面から設定ボトムシートを表示する。
void showGameSettingsDialog(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _SettingsSheet(isGameScreen: true),
  );
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet({required this.isGameScreen});

  final bool isGameScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsViewModelProvider);
    final notifier = ref.read(settingsViewModelProvider.notifier);
    final currentTheme = ref.watch(themeViewModelProvider);
    final brightness = Theme.of(context).brightness;
    final colors = currentTheme.colorsFor(brightness);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
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
          // ハンドル
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t.settings.title.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // サウンド
          _ToggleRow(
            icon: Icons.volume_up_rounded,
            label: t.settings.sound,
            value: settings.soundEnabled,
            onChanged: (_) => notifier.toggleSound(),
            colors: colors,
          ),
          // バイブレーション
          _ToggleRow(
            icon: Icons.vibration_rounded,
            label: t.settings.vibration,
            value: settings.vibrationEnabled,
            onChanged: (_) => notifier.toggleVibration(),
            colors: colors,
          ),
          _SheetDivider(colors: colors),
          // テーマ選択
          _ActionRow(
            icon: Icons.palette_outlined,
            label: '${currentTheme.icon}  ${currentTheme.name}',
            onTap: () {
              Navigator.of(context).pop();
              showThemeSelectorSheet(context);
            },
            colors: colors,
          ),
          // クイズモード専用: 出題方向
          if (isGameScreen &&
              ref.watch(
                blockPuzzleViewModelProvider.select((s) => s.isQuizMode),
              )) ...[
            _SheetDivider(colors: colors),
            _SegmentRow(
              icon: Icons.swap_horiz_rounded,
              label: t.quiz.questionDirection,
              options: [
                t.quiz.questionDirectionEnToJa,
                t.quiz.questionDirectionJaToEn,
                t.quiz.directionRandom,
              ],
              selectedIndex: ref.watch(
                quizViewModelProvider.select(
                  (s) => s.directionMode.index,
                ),
              ),
              onSelected: (int i) => ref
                  .read(quizViewModelProvider.notifier)
                  .setDirectionMode(QuizDirectionMode.values[i]),
              colors: colors,
            ),
          ],
          // ゲーム画面専用: ホームへ戻る・リスタート
          if (isGameScreen) ...[
            _SheetDivider(colors: colors),
            _ActionRow(
              icon: Icons.home_rounded,
              label: t.settings.home,
              onTap: () {
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              colors: colors,
            ),
            _ActionRow(
              icon: Icons.refresh_rounded,
              label: t.settings.restart,
              onTap: () {
                final vm = ref.read(blockPuzzleViewModelProvider);
                final vmNotifier =
                    ref.read(blockPuzzleViewModelProvider.notifier);
                if (vm.isQuizMode) {
                  // シートを閉じてゲーム画面も閉じ → 学習範囲選択画面へ
                  Navigator.of(context)
                    ..pop()
                    ..pop();
                } else if (vm.isQuestMode) {
                  Navigator.of(context).pop();
                  vmNotifier.retryQuestLevel();
                } else {
                  Navigator.of(context).pop();
                  vmNotifier.resetGame();
                }
              },
              colors: colors,
            ),
          ],
          // ホーム画面専用: 利用規約・プライバシーポリシー・お問い合わせ
          if (!isGameScreen) ...[
            _SheetDivider(colors: colors),
            _LinkRow(
              icon: Icons.description_outlined,
              label: t.settings.terms,
              url: AppUrls.termsOfService,
              colors: colors,
            ),
            _LinkRow(
              icon: Icons.privacy_tip_outlined,
              label: t.settings.privacy,
              url: AppUrls.privacyPolicy,
              colors: colors,
            ),
            _LinkRow(
              icon: Icons.mail_outline_rounded,
              label: t.settings.contact,
              url: AppUrls.contact,
              colors: colors,
            ),
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
    required this.colors,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: colors.onSurface,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.accent,
            activeTrackColor: colors.accent.withValues(alpha: 0.2),
            inactiveThumbColor: colors.onSurface.withValues(alpha: 0.3),
            inactiveTrackColor: colors.onSurface.withValues(alpha: 0.1),
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
    required this.colors,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
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
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: colors.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: colors.onSurface.withValues(alpha: 0.3),
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
    required this.colors,
  });

  final IconData icon;
  final String label;
  final String url;
  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
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
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: colors.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: colors.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({
    required this.icon,
    required this.label,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < options.length; i++)
                  GestureDetector(
                    onTap: () => onSelected(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: i == selectedIndex
                            ? colors.accent
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        options[i],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: i == selectedIndex
                              ? colors.surface
                              : colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetDivider extends StatelessWidget {
  const _SheetDivider({required this.colors});

  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: colors.onSurface.withValues(alpha: 0.1),
      height: 16,
    );
  }
}
