import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'animation_config.dart';

mixin AnimationMixin {
  // Entry animations
  Widget animateEntry(Widget child, {Duration? delay}) {
    return child
        .animate(delay: delay ?? Duration.zero)
        .move(
          begin: const Offset(0, 20),
          end: Offset.zero,
          duration: AnimationConfig.standard,
          curve: AnimationConfig.spring,
        )
        .fadeIn(
          duration: AnimationConfig.quick,
          curve: AnimationConfig.standardCurve,
        );
  }

  // Scale tap feedback
  Widget animateScale(Widget child) {
    return child
        .animate(
          target: 0, // This makes it respond to tap
          onPlay: (controller) => controller.forward(from: 0),
        )
        .custom(
          duration: AnimationConfig.quick,
          curve: Curves.easeInOut,
          builder: (context, value, child) => Transform.scale(
            scale: 1.0 - (0.05 * value),
            child: child,
          ),
        );
  }

  // Slide in from direction
  Widget animateSlide(
    Widget child, {
    Offset begin = const Offset(30, 0),
    Duration? delay,
  }) {
    return child
        .animate(delay: delay ?? Duration.zero)
        .move(
          begin: begin,
          end: Offset.zero,
          duration: AnimationConfig.standard,
          curve: AnimationConfig.spring,
        )
        .fadeIn(
          duration: AnimationConfig.quick,
          curve: AnimationConfig.standardCurve,
        );
  }

  // Staggered list animation
  List<Widget> animateList(List<Widget> children) {
    return children.asMap().entries.map((entry) {
      final index = entry.key;
      final child = entry.value;
      return child
          .animate(
            delay: Duration(milliseconds: 50 * index),
          )
          .move(
            begin: const Offset(0, 20),
            end: Offset.zero,
            duration: AnimationConfig.standard,
            curve: AnimationConfig.spring,
          )
          .fadeIn(
            duration: AnimationConfig.quick,
            curve: AnimationConfig.standardCurve,
          );
    }).toList();
  }

  // Hero-like scale animation
  Widget animateExpand(Widget child, {bool isExpanded = false}) {
    return child
        .animate(
          target: isExpanded ? 1 : 0,
        )
        .custom(
          duration: AnimationConfig.standard,
          curve: AnimationConfig.spring,
          builder: (context, value, child) => Transform.scale(
            scale:
                isExpanded ? (0.95 + (0.05 * value)) : (1.0 - (0.05 * value)),
            child: child,
          ),
        )
        .fadeIn(
          duration: AnimationConfig.quick,
          curve: AnimationConfig.standardCurve,
        );
  }

  // Success/completion animation
  Widget animateSuccess(Widget child) {
    return child
        .animate(
          onPlay: (controller) => controller.forward(from: 0),
        )
        .custom(
          duration: AnimationConfig.quick,
          curve: AnimationConfig.spring,
          builder: (context, value, child) => Transform.scale(
            scale: 0.5 + (0.5 * value),
            child: child,
          ),
        )
        .fadeIn(
          duration: AnimationConfig.quick,
          curve: AnimationConfig.standardCurve,
        );
  }

  // Shimmer loading animation
  Widget animateShimmer(Widget child) {
    return child
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .custom(
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            final shimmerGradient = LinearGradient(
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + (value * 3), 0.0),
              end: Alignment(0.0 + (value * 3), 0.0),
            );
            return ShaderMask(
              shaderCallback: (bounds) => shimmerGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: child,
            );
          },
        );
  }
}
