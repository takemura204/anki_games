part of '../settings_sheet.dart';

class _ToggleMenuItem extends StatelessWidget {
  const _ToggleMenuItem({
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

class _ActionMenuItem extends StatelessWidget {
  const _ActionMenuItem({
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
      onTap: onTap.withHaptic(),
      borderRadius: AppBorderRadius.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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

class _LinkMenuItem extends StatelessWidget {
  const _LinkMenuItem({
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
      onTap: (() => launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView))
          .withHaptic(),
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

class _SegmentedMenuItem extends ConsumerWidget {
  const _SegmentedMenuItem();

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

class _DeleteDataMenuItem extends ConsumerWidget {
  const _DeleteDataMenuItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: (() => _onTap(context, ref)).withHaptic(),
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
