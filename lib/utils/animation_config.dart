import 'dart:math' show exp, sin, sqrt;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SpringCurve extends Curve {
  final double mass;
  final double stiffness;
  final double damping;

  const SpringCurve({
    this.mass = 1.0,
    this.stiffness = 180.0,
    this.damping = 17.0,
  });

  @override
  double transformInternal(double t) {
    final oscillation =
        -0.5 * exp(-damping * t) * sin(sqrt(stiffness / mass) * t);
    return 1.0 + oscillation;
  }
}

class AnimationConfig {
  // Standard durations
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 350);
  static const Duration long = Duration(milliseconds: 500);

  // Spring configurations
  static const springStiffness = 180.0;
  static const springDamping = 17.0;

  // Standard curves
  static const standardCurve = Cubic(0.42, 0, 0.58, 1.0);
  static const emphasizedCurve = Cubic(0.17, 0.17, 0, 1.0);

  // Spring animations
  static SpringCurve get spring => SpringCurve(
        mass: 1.0,
        stiffness: springStiffness,
        damping: springDamping,
      );

  // Preset effects
  static List<Effect> fadeIn() => [
        FadeEffect(
          duration: quick,
          curve: standardCurve,
          begin: 0.0,
          end: 1.0,
        ),
      ];

  static List<Effect> scaleIn() => [
        ScaleEffect(
          duration: standard,
          curve: spring,
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
        ),
      ];

  static List<Effect> slideUp() => [
        SlideEffect(
          duration: standard,
          curve: spring,
          begin: const Offset(0, 20),
          end: Offset.zero,
        ),
      ];

  static List<Effect> emphasis() => [
        ScaleEffect(
          duration: quick,
          curve: emphasizedCurve,
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.05, 1.05),
        ),
        ScaleEffect(
          duration: quick,
          curve: emphasizedCurve,
          begin: const Offset(1.05, 1.05),
          end: const Offset(1.0, 1.0),
        ),
      ];
}
