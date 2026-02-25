import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/block_puzzle/model/game_theme.dart';
import 'package:mono_games/features/block_puzzle/model/game_themes.dart';
import 'package:mono_games/features/block_puzzle/view/widgets/theme_block_preview.dart';
import 'package:mono_games/features/block_puzzle/view_model/theme_view_model.dart';

/// テーマ選択ボトムシートを表示する。
void showThemeSelectorSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _ThemeSelectorSheet(),
  );
}

class _ThemeSelectorSheet extends ConsumerStatefulWidget {
  const _ThemeSelectorSheet();

  @override
  ConsumerState<_ThemeSelectorSheet> createState() =>
      _ThemeSelectorSheetState();
}

class _ThemeSelectorSheetState extends ConsumerState<_ThemeSelectorSheet> {
  late String _pendingThemeId;

  @override
  void initState() {
    super.initState();
    _pendingThemeId = ref.read(themeViewModelProvider).id;
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeViewModelProvider);
    final brightness = Theme.of(context).brightness;
    final currentColors = currentTheme.colorsFor(brightness);

    final pendingTheme = allGameThemes.firstWhere(
      (t) => t.id == _pendingThemeId,
      orElse: () => allGameThemes.first,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: currentColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
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
            // プレビュー
            ThemeBlockPreview(theme: pendingTheme, cellSize: 24),
            const SizedBox(height: 8),
            Text(
              pendingTheme.name,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: currentColors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            // テーマボタン 2列グリッド
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 4),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 56,
                ),
                itemCount: allGameThemes.length,
                itemBuilder: (_, index) {
                  final theme = allGameThemes[index];
                  return _ThemeButton(
                    theme: theme,
                    isSelected: theme.id == _pendingThemeId,
                    brightness: brightness,
                    colors: currentColors,
                    onTap: () =>
                        setState(() => _pendingThemeId = theme.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // 確定ボタン
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: currentColors.onSurface,
                  foregroundColor: currentColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ref
                      .read(themeViewModelProvider.notifier)
                      .selectTheme(_pendingThemeId);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.theme,
    required this.isSelected,
    required this.brightness,
    required this.colors,
    required this.onTap,
  });

  final GameTheme theme;
  final bool isSelected;
  final Brightness brightness;
  final GameThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colors.onSurface
                : colors.onSurface.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            ThemeSingleBlock(theme: theme, brightness: brightness, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                theme.name,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: colors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
