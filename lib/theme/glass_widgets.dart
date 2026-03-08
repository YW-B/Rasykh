import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// A frosted-glass panel matching the React `.glass-panel` CSS class.
///
/// Uses [BackdropFilter] with blur, emerald-tinted fill,
/// subtle white border, and inner/outer shadow simulation.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.margin,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: borderColor ?? AppColors.glassBorder),
              boxShadow: const [
                // Inner glow simulation
                BoxShadow(
                  color: Color(0x0DFFFFFF), // 5% white
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
                // Outer shadow
                BoxShadow(
                  color: Color(0x33000000), // 20% black
                  blurRadius: 32,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A small glass-styled button matching the React `.glass-button` CSS class.
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 100,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppColors.emerald500.withValues(alpha: 0.15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.glassButtonFill,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.glassButtonBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
