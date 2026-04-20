part of '../filter_sheet.dart';

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {this.trailing});

  final String label;
  final Widget? trailing;

  static const _style = TextStyle(
    color: Color(0x80FFFFFF),
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    if (trailing == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label, style: _style),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label, style: _style),
          const Spacer(),
          trailing!,
        ],
      ),
    );
  }
}
