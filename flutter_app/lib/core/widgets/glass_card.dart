import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/constants.dart';

/// A glassmorphism-style card widget with blur effect and translucent background.
/// Provides a modern, frosted glass appearance with customizable border, blur, and padding.
/// Can be made tappable by providing an onTap callback.
class GlassCard extends StatelessWidget {
  /// The child widget to display inside the card.
  final Widget child;

  /// The border radius of the card corners. Defaults to 16.
  final double borderRadius;

  /// The padding inside the card. Defaults to EdgeInsets.all(20).
  final EdgeInsetsGeometry? padding;

  /// The blur intensity for the glass effect. Defaults to 10.
  final double blur;

  /// The color of the card border. Defaults to a semi-transparent primary accent color.
  final Color? borderColor;

  /// Optional callback function to execute when the card is tapped.
  final VoidCallback? onTap;

  /// Creates a GlassCard with the given child and optional styling parameters.
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.blur = 10,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border =
        borderColor ?? const Color(AppConstants.primaryAccent).withValues(alpha: 0.2);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(AppConstants.backgroundSecondary)
                  .withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: border, width: 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.01),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
