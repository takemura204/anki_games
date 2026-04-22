part of '../filter_sheet.dart';

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({
    required this.canApply,
    required this.isApplying,
    required this.onTap,
  });

  final bool canApply;
  final bool isApplying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: GestureDetector(
        onTap: (canApply && !isApplying) ? onTap : null,
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          height: 52,
          decoration: BoxDecoration(
            gradient: canApply
                ? const LinearGradient(
                    colors: [AppColors.itPassSeed, AppColors.itPassAccent],
                  )
                : null,
            color: canApply ? null : c.surface2,
            borderRadius: AppBorderRadius.lg,
          ),
          child: Center(
            child: isApplying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    canApply ? 'この設定で出題する' : '試験回を選択してください',
                    style: AppTextStyle.titleMedium.copyWith(
                      color: canApply ? Colors.white : c.fgShade200,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
