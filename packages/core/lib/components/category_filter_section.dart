import 'package:core/config/brand/it_pass_color_scheme.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// 大項目（システム）のアコーディオンタイル。
/// filter_sheet とオンボーディングカテゴリ選択の両方で使用する。
class CategoryExpansionTile extends StatelessWidget {
  const CategoryExpansionTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.isExpanded,
    required this.onSelectToggle,
    required this.onExpansionToggle,
    required this.child,
  });

  final String title;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onSelectToggle;
  final VoidCallback onExpansionToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: AppBorderRadius.md,
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          decoration: BoxDecoration(
            color: isSelected
                ? ItPassColors.seed.withValues(alpha: 0.12)
                : c.surface1,
            borderRadius: AppBorderRadius.md,
            border: Border.all(
              color: isSelected ? ItPassColors.seed : c.border1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onSelectToggle.withHaptic(HapticType.selection),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? ItPassColors.seed
                                    : c.fgShade200,
                                size: AppSpacing.md + 4,
                              ),
                              const Gap(AppSpacing.sm),
                              Text(
                                title,
                                style: AppTextStyle.bodySmall.copyWith(
                                  color: isSelected ? c.fg : c.fgShade400,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onExpansionToggle.withHaptic(),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: AppAnimation.fast,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: c.fgShade200,
                            size: AppSpacing.md + 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: AppAnimation.fast,
                  curve: Curves.easeOut,
                  child: isExpanded
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.sm,
                            0,
                            AppSpacing.sm,
                            AppSpacing.md,
                          ),
                          child: child,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 中項目チップ。
class CategoryMajorChip extends StatelessWidget {
  const CategoryMajorChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      borderRadius: AppBorderRadius.sm,
      child: InkWell(
        borderRadius: AppBorderRadius.sm,
        onTap: onTap.withHaptic(HapticType.selection),
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? ItPassColors.seed.withValues(alpha: 0.25)
                : c.surface1,
            borderRadius: AppBorderRadius.sm,
            border: Border.all(
              color: isSelected
                  ? ItPassColors.seed.withValues(alpha: 0.7)
                  : c.border1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyle.labelLarge.copyWith(
              color: isSelected ? c.fg : c.fgShade300,
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
