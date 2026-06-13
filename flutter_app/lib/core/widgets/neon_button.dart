import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/constants.dart';

/// A custom button widget with neon glow effects and animations.
/// Features a glowing border, scale animation on press, and optional loading state.
/// Supports custom colors, width, height, and icons.
class NeonButton extends StatefulWidget {
  /// The text label displayed on the button.
  final String label;

  /// Callback function executed when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is in a loading state, showing a progress indicator.
  final bool isLoading;

  /// The color of the button's glow and text. Defaults to primary accent color.
  final Color? color;

  /// The width of the button. If null, the button will size to its content.
  final double? width;

  /// The height of the button. Defaults to 52.
  final double height;

  /// Optional icon to display before the label.
  final IconData? icon;

  /// Creates a NeonButton with the given label and optional styling parameters.
  const NeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.width,
    this.height = 52,
    this.icon,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

/// The state class for NeonButton that handles animation logic.
class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  /// Animation controller for the button press scale effect.
  late AnimationController _controller;

  /// Scale animation that shrinks the button slightly when pressed.
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 150), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor =
        widget.color ?? const Color(AppConstants.primaryAccent);
    final isDisabled = widget.onPressed == null || widget.isLoading;
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: isDisabled
                ? buttonColor.withValues(alpha: 0.15)
                : buttonColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled
                  ? buttonColor.withValues(alpha: 0.3)
                  : buttonColor,
              width: 1.5,
            ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                        color: buttonColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 0),
                    BoxShadow(
                        color: buttonColor.withValues(alpha: 0.15),
                        blurRadius: 24,
                        spreadRadius: 2),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(buttonColor)),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: buttonColor, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: GoogleFonts.orbitron(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDisabled
                              ? buttonColor.withValues(alpha: 0.5)
                              : buttonColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
