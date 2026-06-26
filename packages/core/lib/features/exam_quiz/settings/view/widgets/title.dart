part of '../settings_sheet.dart';

class _Title extends StatelessWidget {
  const _Title({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding:
            const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
        child: Text(title,
            style: AppTextStyle.labelMedium.copyWith(
              color: context.appColors.fgShade300,
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }
}
