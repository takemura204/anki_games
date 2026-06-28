import 'dart:ui';
import 'package:core/config/brand/app_color_scheme.dart';
import 'package:core/config/styles/app_spacing.dart';
import 'package:flutter/material.dart';

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.cardRadius,
    required this.child,
    this.padding,
  });

  final BorderRadius cardRadius;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ClipRRect(
      borderRadius: cardRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppSpacing.md, sigmaY: AppSpacing.md),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            color: c.surface1,
            border: Border.all(color: c.border2),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.cardRadius,
    required this.child,
    this.padding,
    this.width,
  });

  final BorderRadius cardRadius;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return ClipRRect(
      borderRadius: cardRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppSpacing.md, sigmaY: AppSpacing.md),
        child: Container(
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            color: c.surface2,
            border: Border.all(color: c.border2),
          ),
          child: child,
        ),
      ),
    );
  }
}
