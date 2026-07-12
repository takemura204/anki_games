part of '../filter_sheet.dart';

class _FilterSectionCard extends StatelessWidget {
  const _FilterSectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: AppBorderRadius.lg,
        border: Border.all(color: c.border1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}
