import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:focus_flow/core/constants/theme/app_colors.dart';

class ProductivityRingPainter extends CustomPainter {
  final double progress;
  final double lifeProgress;
  final bool isDark;

  ProductivityRingPainter({
    required this.progress,
    required this.lifeProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final backgroundPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;

    canvas.drawCircle(center, radius, backgroundPaint);

    final foregroundPaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      foregroundPaint,
    );

    if (progress > 0) {
      final angle = -math.pi / 2 + math.pi * 2 * progress.clamp(0.0, 1.0);
      final pulse = 1 + math.sin(lifeProgress * math.pi * 2) * 0.20;

      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      final glowPaint = Paint()
        ..color = AppColors.secondary.withValues(alpha: isDark ? 0.30 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(point, 5 * pulse, glowPaint);
      canvas.drawCircle(point, 2.8, Paint()..color = AppColors.secondary);
    }
  }

  @override
  bool shouldRepaint(covariant ProductivityRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.lifeProgress != lifeProgress ||
        oldDelegate.isDark != isDark;
  }
}

class PulseScorePainter extends CustomPainter {
  final double progress;
  final double lifeProgress;
  final bool isDark;

  PulseScorePainter({
    required this.progress,
    required this.lifeProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 9;
    final pulse = math.sin(lifeProgress * math.pi * 2).abs();

    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(
        alpha: (isDark ? 0.11 : 0.07) + pulse * 0.04,
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(center, radius + 4 + pulse * 3, glowPaint);

    final backgroundPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.primary, AppColors.secondary, AppColors.primary],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );

    final orbitAngle = lifeProgress * math.pi * 2;
    final orbitPoint = Offset(
      center.dx + math.cos(orbitAngle) * (radius + 1),
      center.dy + math.sin(orbitAngle) * (radius + 1),
    );

    final dotPaint = Paint()
      ..color = AppColors.secondary
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawCircle(orbitPoint, 3.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant PulseScorePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.lifeProgress != lifeProgress ||
        oldDelegate.isDark != isDark;
  }
}
