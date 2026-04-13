import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool hasGlow;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.hasGlow = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final neonColor = borderColor ?? AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: neonColor.withValues(alpha: 0.25),
                  blurRadius: 32,
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: neonColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ]
            : [
                BoxShadow(
                  color: neonColor.withValues(alpha: 0.06),
                  blurRadius: 12,
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                width: hasGlow ? 1.2 : 0.8,
                color: neonColor.withValues(alpha: hasGlow ? 0.35 : 0.15),
              ),
            ),
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
