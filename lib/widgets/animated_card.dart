import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/animation_config.dart';
import '../utils/animation_mixin.dart';
import 'ui_components.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.isSelected = false,
    this.onTap,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> with AnimationMixin {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardDecoration = BoxDecoration(
      color: widget.backgroundColor ?? Colors.white,
      borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
      boxShadow: widget.boxShadow ??
          [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
    );

    Widget card = Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      decoration: cardDecoration,
      child: widget.child,
    );

    // Apply selection animation
    if (widget.isSelected) {
      card = card.animate().custom(
            duration: AnimationConfig.quick,
            curve: AnimationConfig.spring,
            builder: (context, value, child) => Transform.scale(
              scale: 1.02,
              child: Container(
                decoration: cardDecoration.copyWith(
                  boxShadow: [
                    BoxShadow(
                      color: GreenPayUI.primaryColor.withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
    }

    // Apply press animation
    if (widget.onTap != null) {
      card = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: card.animate(target: _isPressed ? 1 : 0).custom(
              duration: AnimationConfig.quick,
              curve: Curves.easeInOut,
              builder: (context, value, child) => Transform.scale(
                scale: 1.0 - (0.02 * value),
                child: Container(
                  decoration: cardDecoration.copyWith(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05 * (1 - value)),
                        blurRadius: 10 * (1 - value),
                        offset: Offset(0, 4 * (1 - value)),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
      );
    }

    // Apply entry animation
    return animateEntry(card);
  }
}
