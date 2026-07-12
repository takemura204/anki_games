import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/haptic/haptics.dart';
import 'package:core/config/styles/app_animation.dart';
import 'package:core/config/styles/app_border_radius.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:core/config/styles/app_text_style.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;
  final double height;

  bool get _enabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    return ClipRRect(
      borderRadius: AppBorderRadius.lg,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _enabled ? onPressed!.withHaptic(HapticType.medium) : null,
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: AppAnimation.fast,
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: _enabled
                  ? const LinearGradient(
                      colors: [AppPalette.seed, AppPalette.accent],
                    )
                  : null,
              color: _enabled ? null : c.surface2,
              borderRadius: AppBorderRadius.lg,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            color: _enabled ? Colors.white : c.fgShade200,
                            size: 20,
                          ),
                          const Gap(AppSpacing.sm),
                        ],
                        Text(
                          label,
                          style: AppTextStyle.titleMedium.copyWith(
                            color: _enabled ? Colors.white : c.fgShade200,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (trailingIcon != null) ...[
                          const Gap(AppSpacing.sm),
                          Icon(
                            trailingIcon,
                            color: _enabled ? Colors.white : c.fgShade200,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
