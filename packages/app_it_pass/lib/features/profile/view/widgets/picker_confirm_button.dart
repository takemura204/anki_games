import 'package:app_it_pass/config/theme/it_pass_color_scheme.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_colors.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:flutter/material.dart';

class PickerConfirmButton extends StatelessWidget {
  const PickerConfirmButton({
    super.key,
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      child: ClipRRect(
        borderRadius: AppBorderRadius.lg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap.withHaptic(HapticType.medium) : null,
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: AnimatedContainer(
              duration: AppAnimation.fast,
              height: 56,
              decoration: BoxDecoration(
                gradient: enabled
                    ? const LinearGradient(
                        colors: [AppColors.itPassSeed, AppColors.itPassAccent],
                      )
                    : null,
                color: enabled ? null : c.surface2,
                borderRadius: AppBorderRadius.lg,
              ),
              child: Center(
                child: Text(
                  '選択する',
                  style: AppTextStyle.titleMedium.copyWith(
                    color: enabled ? Colors.white : c.fgShade200,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
