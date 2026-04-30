part of '../report_sheet.dart';

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.onClose});

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
                Icon(AppIcons.report, color: c.fgShade400),
                const Gap(AppSpacing.xs),
                Text(
                  'レポート',
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
              onPressed: onClose,
            ),
          ),
        ],
      ),
    );
  }
}
