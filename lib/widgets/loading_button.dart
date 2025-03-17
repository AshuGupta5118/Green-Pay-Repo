import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/animation_config.dart';
import 'ui_components.dart';

class LoadingButton extends StatefulWidget {
  final String text;
  final Future<void> Function() onPressed;
  final bool isEnabled;
  final Color? backgroundColor;
  final double? width;
  final IconData? icon;

  const LoadingButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isEnabled = true,
    this.backgroundColor,
    this.width,
    this.icon,
  }) : super(key: key);

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading || !widget.isEnabled) return;

    setState(() => _isLoading = true);

    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: widget.isEnabled ? _handlePress : null,
        style: GreenPayUI.primaryButtonStyle(
          backgroundColor: widget.backgroundColor,
        ),
        child: AnimatedSwitcher(
          duration: AnimationConfig.quick,
          switchInCurve: AnimationConfig.spring,
          switchOutCurve: AnimationConfig.spring,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation.drive(
                  Tween<double>(begin: 0.95, end: 1.0),
                ),
                child: child,
              ),
            );
          },
          child: _isLoading
              ? Container(
                  key: const ValueKey('loader'),
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.backgroundColor != null
                          ? Colors.white
                          : GreenPayUI.primaryColor,
                    ),
                  ),
                )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .custom(
                    duration: const Duration(milliseconds: 1500),
                    builder: (context, value, child) => Transform.rotate(
                      angle: value * 2 * 3.14159,
                      child: child,
                    ),
                  )
              : Row(
                  key: const ValueKey('content'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: GreenPayUI.calloutStyle.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.41,
                      ),
                    ),
                  ],
                )
                  .animate()
                  .custom(
                    duration: AnimationConfig.quick,
                    curve: AnimationConfig.standardCurve,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: child,
                    ),
                  )
                  .custom(
                    duration: AnimationConfig.standard,
                    curve: AnimationConfig.spring,
                    builder: (context, value, child) => Transform.scale(
                      scale: 0.95 + (0.05 * value),
                      child: child,
                    ),
                  ),
        ),
      ),
    );
  }
}
