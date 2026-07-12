part of '../profile_page.dart';

class _ProfileFieldRow extends StatelessWidget {
  const _ProfileFieldRow({
    required this.label,
    required this.onTap,
    this.value,
    this.placeholder = '未設定',
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      onTap: onTap.withHaptic(),
      borderRadius: AppBorderRadius.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyle.bodyMedium.copyWith(color: c.fg),
              ),
            ),
            Text(
              value ?? placeholder,
              style: AppTextStyle.bodySmall.copyWith(
                color: value != null ? c.fg : c.fgShade400,
              ),
            ),
            const Gap(AppSpacing.xs),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.fgShade300),
          ],
        ),
      ),
    );
  }
}
