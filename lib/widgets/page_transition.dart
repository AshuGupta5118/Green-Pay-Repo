import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/animation_config.dart';

enum PageTransitionType {
  fade,
  slideUp,
  slideLeft,
  scale,
  scaleWithFade,
}

class PageTransition extends StatelessWidget {
  final Widget child;
  final PageTransitionType type;
  final Duration? duration;
  final Curve? curve;

  const PageTransition({
    Key? key,
    required this.child,
    this.type = PageTransitionType.slideUp,
    this.duration,
    this.curve,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case PageTransitionType.fade:
        return child.animate().custom(
              duration: duration ?? AnimationConfig.standard,
              curve: curve ?? AnimationConfig.standardCurve,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: child,
              ),
            );

      case PageTransitionType.slideUp:
        return child.animate().custom(
              duration: duration ?? AnimationConfig.standard,
              curve: curve ?? AnimationConfig.spring,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              ),
            );

      case PageTransitionType.slideLeft:
        return child.animate().custom(
              duration: duration ?? AnimationConfig.standard,
              curve: curve ?? AnimationConfig.spring,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(30 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              ),
            );

      case PageTransitionType.scale:
        return child.animate().custom(
              duration: duration ?? AnimationConfig.standard,
              curve: curve ?? AnimationConfig.spring,
              builder: (context, value, child) => Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: child,
              ),
            );

      case PageTransitionType.scaleWithFade:
        return child.animate().custom(
              duration: duration ?? AnimationConfig.standard,
              curve: curve ?? AnimationConfig.spring,
              builder: (context, value, child) => Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              ),
            );
    }
  }

  static Route<T> route<T>({
    required Widget page,
    PageTransitionType type = PageTransitionType.slideUp,
    Duration? duration,
    Curve? curve,
    bool fullscreenDialog = false,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => PageTransition(
        type: type,
        duration: duration,
        curve: curve,
        child: page,
      ),
      transitionDuration: duration ?? AnimationConfig.standard,
      fullscreenDialog: fullscreenDialog,
    );
  }
}
