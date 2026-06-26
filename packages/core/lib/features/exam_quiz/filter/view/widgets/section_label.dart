part of '../filter_sheet.dart';

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyle.labelMedium.copyWith(
      color: context.appColors.fgShade300,
    );

    if (trailing == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label, style: style),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          trailing!,
        ],
      ),
    );
  }
}
