part of '../settings_sheet.dart';

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.valueText,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final IconData? trailingIcon;
  final String? valueText;

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
            if (valueText != null) ...[
              Text(
                valueText!,
                style: AppTextStyle.bodySmall.copyWith(color: c.fgShade300),
              ),
              const Gap(AppSpacing.xs),
            ],
            if (trailingIcon != null)
              Icon(trailingIcon, size: 18, color: c.fgShade200),
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
    this.launchMode = LaunchMode.inAppWebView,
  });

  final IconData icon;
  final String label;
  final String url;
  final LaunchMode launchMode;

  @override
  Widget build(BuildContext context) {
    return _MenuItem(
      icon: icon,
      label: label,
      onTap: () => launchUrl(Uri.parse(url), mode: launchMode),
      trailingIcon: null,
    );
  }
}

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
            activeThumbColor: ItPassColors.seed,
            activeTrackColor: ItPassColors.seed.withValues(alpha: 0.25),
            inactiveThumbColor: c.fgShade200,
            inactiveTrackColor: c.surface2,
          ),
        ],
      ),
    );
  }
}
