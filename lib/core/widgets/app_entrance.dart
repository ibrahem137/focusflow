import 'package:flutter/material.dart';

/// Shared entrance treatment. CurveTween avoids allocating a listening
/// CurvedAnimation on every build; the child stays outside frame rebuilds.
class AppEntrance extends StatelessWidget {
  final AnimationController controller;
  final double begin, end, offsetY, beginScale;
  final Widget child;
  const AppEntrance({
    super.key,
    required this.controller,
    required this.begin,
    required this.end,
    required this.child,
    this.offsetY = 24,
    this.beginScale = 0.97,
  });
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final safeBegin = begin.clamp(0.0, 0.95);
    final animation = controller.drive(
      CurveTween(
        curve: Interval(
          safeBegin,
          end.clamp(safeBegin + 0.01, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (_, child) {
        final value = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - value)),
            child: Transform.scale(
              scale: beginScale + (1 - beginScale) * value,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
