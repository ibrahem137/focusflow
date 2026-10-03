import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:focus_flow/core/constants/theme/app_colors.dart';

class GardenAtmospherePainter extends CustomPainter {
  final double progress;
  final bool isDark;

  GardenAtmospherePainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    const particleCount = 13;

    for (var i = 0; i < particleCount; i++) {
      final phase = (progress + i / particleCount) % 1.0;
      final baseX = ((i * 47) % 100) / 100;
      final x =
          size.width *
          (0.12 + baseX * 0.76 + math.sin(progress * math.pi * 2 + i) * 0.025);
      final y = size.height * (0.88 - phase * 0.76);

      final opacity =
          math.sin(phase * math.pi).clamp(0.0, 1.0) * (isDark ? 0.22 : 0.16);

      final paint = Paint()
        ..color = AppColors.secondary.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(Offset(x, y), 1.5 + (i % 3) * 0.65, paint);
    }
  }

  @override
  bool shouldRepaint(covariant GardenAtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}

class LivingTreePainter extends CustomPainter {
  final int sessions;
  final double lifeProgress;
  final double growthProgress;
  final bool isDark;

  LivingTreePainter({
    required this.sessions,
    required this.lifeProgress,
    required this.growthProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final groundY = size.height - 16;

    _paintGround(canvas, size, centerX, groundY);

    if (sessions <= 0) {
      _paintSeed(canvas, centerX, groundY);
      return;
    }

    final stage = sessions.clamp(1, 4);
    final stageFactor = stage / 4.0;
    final grow = growthProgress.clamp(0.0, 1.0);

    final sway =
        math.sin(lifeProgress * math.pi * 2) * (1.2 + stageFactor * 1.8);

    final trunkHeight = (48 + stageFactor * 92) * grow;
    final trunkTop = Offset(centerX + sway, groundY - trunkHeight);

    final trunkPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF8B5A2B),
        const Color(0xFF5A3A1B),
        stageFactor,
      )!
      ..strokeWidth = 5 + stageFactor * 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final trunkPath = Path()
      ..moveTo(centerX, groundY)
      ..cubicTo(
        centerX - 3,
        groundY - trunkHeight * 0.32,
        centerX + sway * 0.3,
        groundY - trunkHeight * 0.68,
        trunkTop.dx,
        trunkTop.dy,
      );

    canvas.drawPath(trunkPath, trunkPaint);

    if (stage >= 2) {
      _paintBranch(
        canvas,
        trunkTop,
        Offset(
          centerX - (25 + stageFactor * 16) + sway * 0.45,
          groundY - trunkHeight * 0.68,
        ),
        4.5 + stageFactor * 3,
      );

      _paintBranch(
        canvas,
        Offset(centerX, groundY - trunkHeight * 0.55),
        Offset(
          centerX + (27 + stageFactor * 18) + sway * 0.6,
          groundY - trunkHeight * 0.75,
        ),
        4.0 + stageFactor * 3,
      );
    }

    if (stage >= 3) {
      _paintBranch(
        canvas,
        Offset(centerX + sway * 0.2, groundY - trunkHeight * 0.76),
        Offset(centerX - 43 + sway, groundY - trunkHeight * 0.90),
        4.5,
      );

      _paintBranch(
        canvas,
        Offset(centerX + sway * 0.2, groundY - trunkHeight * 0.80),
        Offset(centerX + 46 + sway, groundY - trunkHeight * 0.94),
        4.5,
      );
    }

    _paintLeaves(
      canvas,
      size,
      centerX,
      groundY,
      trunkHeight,
      stage,
      sway,
      grow,
    );

    if (stage >= 4) {
      _paintFallingLeaf(canvas, size, centerX);
    }
  }

  @override
  bool shouldRepaint(covariant LivingTreePainter oldDelegate) {
    return oldDelegate.sessions != sessions ||
        oldDelegate.lifeProgress != lifeProgress ||
        oldDelegate.growthProgress != growthProgress ||
        oldDelegate.isDark != isDark;
  }

  void _paintBranch(Canvas canvas, Offset from, Offset to, double width) {
    final paint = Paint()
      ..color = const Color(0xFF6D4724)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(from, to, paint);
  }

  void _paintFallingLeaf(Canvas canvas, Size size, double centerX) {
    final cycle = lifeProgress;
    final y = 55 + cycle * 120;
    final x = centerX + 58 + math.sin(cycle * math.pi * 4) * 16;

    final paint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 1 - cycle * 0.55);

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(cycle * math.pi * 3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 11, height: 6),
      paint,
    );
    canvas.restore();
  }

  void _paintGround(Canvas canvas, Size size, double centerX, double groundY) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.18 : 0.08);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, groundY + 3),
        width: 120,
        height: 18,
      ),
      shadowPaint,
    );

    final soilPaint = Paint()
      ..color = const Color(0xFF795548).withValues(alpha: 0.30);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, groundY), width: 92, height: 13),
      soilPaint,
    );
  }

  void _paintLeaves(
    Canvas canvas,
    Size size,
    double centerX,
    double groundY,
    double trunkHeight,
    int stage,
    double sway,
    double grow,
  ) {
    final leafCount = switch (stage) {
      1 => 4,
      2 => 10,
      3 => 24,
      _ => 42,
    };

    final canopyWidth = switch (stage) {
      1 => 30.0,
      2 => 65.0,
      3 => 105.0,
      _ => 145.0,
    };

    final canopyHeight = switch (stage) {
      1 => 34.0,
      2 => 58.0,
      3 => 82.0,
      _ => 105.0,
    };

    final canopyCenterY =
        groundY - trunkHeight + (stage == 1 ? 0 : canopyHeight * 0.18);

    for (var i = 0; i < leafCount; i++) {
      final angle =
          (i * 2.399963229728653) +
          math.sin(lifeProgress * math.pi * 2 + i) * 0.025;

      final radiusFactor = math.sqrt((i + 1) / leafCount);
      final x =
          centerX +
          math.cos(angle) * canopyWidth * 0.48 * radiusFactor +
          sway * (0.45 + radiusFactor * 0.55);
      final y =
          canopyCenterY + math.sin(angle) * canopyHeight * 0.42 * radiusFactor;

      final leafWave = math.sin(lifeProgress * math.pi * 2 + i * 0.83) * 1.8;

      final leafSize = (stage == 1 ? 8.0 : 6.5 + (i % 4) * 1.25) * grow;

      final palette = [
        const Color(0xFF16A34A),
        const Color(0xFF22C55E),
        const Color(0xFF4ADE80),
        const Color(0xFF15803D),
      ];

      final paint = Paint()
        ..color = palette[i % palette.length].withValues(alpha: 0.90);

      canvas.save();
      canvas.translate(x, y + leafWave);
      canvas.rotate(angle * 0.18);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: leafSize * 1.55,
        height: leafSize,
      );

      canvas.drawOval(rect, paint);
      canvas.restore();
    }

    if (stage >= 3) {
      final glow = Paint()
        ..color = AppColors.secondary.withValues(
          alpha: 0.05 + 0.025 * math.sin(lifeProgress * math.pi * 2).abs(),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

      canvas.drawCircle(
        Offset(centerX + sway, canopyCenterY),
        canopyWidth * 0.50,
        glow,
      );
    }
  }

  void _paintSeed(Canvas canvas, double centerX, double groundY) {
    final pulse = 1 + math.sin(lifeProgress * math.pi * 2) * 0.05;

    canvas.save();
    canvas.translate(centerX, groundY - 9);
    canvas.scale(pulse);

    final seedPaint = Paint()..color = const Color(0xFF6D4C41);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 15, height: 20),
      seedPaint,
    );

    final glowPaint = Paint()
      ..color = AppColors.secondary.withValues(
        alpha: 0.08 + 0.04 * math.sin(lifeProgress * math.pi * 2).abs(),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawCircle(Offset.zero, 24, glowPaint);
    canvas.restore();
  }
}
