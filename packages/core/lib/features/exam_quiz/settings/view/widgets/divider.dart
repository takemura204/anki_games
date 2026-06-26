part of '../settings_sheet.dart';

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(color: context.appColors.fgShade50, height: AppSpacing.lg);
  }
}
