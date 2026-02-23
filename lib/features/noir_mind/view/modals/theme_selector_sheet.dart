import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/noir_mind/model/game_theme.dart';
import 'package:mono_games/features/noir_mind/model/game_themes.dart';
import 'package:mono_games/features/noir_mind/view_model/theme_view_model.dart';

/// テーマ選択ボトムシートを表示する。
void showThemeSelectorSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ThemeSelectorSheet(),
  );
}

class _ThemeSelectorSheet extends ConsumerWidget {
  const _ThemeSelectorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeViewModelProvider);
    final brightness = Theme.of(context).brightness;
    final currentColors = currentTheme.colorsFor(brightness);

    return Container(
      decoration: BoxDecoration(
        color: currentColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ハンドル
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: currentColors.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'THEME',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: currentColors.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            // テーマカード一覧
            ...allGameThemes.map(
              (theme) => _ThemeCard(
                theme: theme,
                isSelected: theme.id == currentTheme.id,
                onTap: () {
                  ref
                      .read(themeViewModelProvider.notifier)
                      .selectTheme(theme.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  final GameTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colorsFor(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colors.onSurface
                    : colors.onSurface.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // カラープレビュードット
                _ColorDots(colors: colors),
                const SizedBox(width: 14),
                // テーマ名
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${theme.icon}  ${theme.name}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                // 選択インジケータ
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colors.onSurface,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorDots extends StatelessWidget {
  const _ColorDots({required this.colors});

  final GameThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        children: [
          // 背景色ドット（大）
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.onSurface.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          // 前景色ドット
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: colors.onSurface,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // アクセント色ドット（小）
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
