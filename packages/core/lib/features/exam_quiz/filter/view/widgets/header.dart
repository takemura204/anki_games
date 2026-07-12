part of '../filter_sheet.dart';

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  AppIcons.filter,
                  color: c.fgShade400,
                ),
                const Gap(AppSpacing.xs),
                Text(
                  '絞り込み',
                  style: AppTextStyle.titleLarge.copyWith(
                    color: c.fgShade400,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.sm),
          GlassButton(
            cardRadius: AppBorderRadius.circle,
            child: IconButton(
              icon: Icon(AppIcons.close, color: c.fgShade300),
              onPressed: onClose.withHaptic(),
            ),
          ),
        ],
      ),
    );
  }
}
