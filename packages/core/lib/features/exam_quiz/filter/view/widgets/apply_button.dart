part of '../filter_sheet.dart';

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({
    required this.canApply,
    required this.isApplying,
    required this.buttonText,
    required this.onTap,
  });

  final bool canApply;
  final bool isApplying;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: PrimaryButton(
        label: buttonText,
        onPressed: canApply ? onTap : null,
        isLoading: isApplying,
        height: 60,
      ),
    );
  }
}
