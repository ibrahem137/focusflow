part of '../onboarding_screen.dart';

class _BackgroundLeaves extends StatelessWidget {
  final double progress;
  final int page;

  const _BackgroundLeaves({required this.progress, required this.page});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned(
          left: 8,
          bottom: 20,
          child: Transform.rotate(
            angle: -.5 + progress * .08,
            child: Icon(
              Icons.eco_rounded,
              size: 75,
              color: colors.secondary.withValues(alpha: .45),
            ),
          ),
        ),
        Positioned(
          right: 4,
          bottom: 35,
          child: Transform.rotate(
            angle: .5 - progress * .08,
            child: Icon(
              Icons.eco_rounded,
              size: 66,
              color: colors.primary.withValues(alpha: .35),
            ),
          ),
        ),
        Positioned(
          left: 30,
          top: 65,
          child: Transform.rotate(
            angle: -.7,
            child: Icon(
              Icons.eco_rounded,
              size: 34,
              color: colors.secondary.withValues(alpha: .65),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClockPainter extends CustomPainter {
  final Color color;

  _ClockPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final tickPaint = Paint()
      ..color = color.withValues(alpha: .65)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 4; i++) {
      final angle = (math.pi / 2) * i;

      final start = Offset(
        center.dx + math.cos(angle) * 51,
        center.dy + math.sin(angle) * 51,
      );

      final end = Offset(
        center.dx + math.cos(angle) * 57,
        center.dy + math.sin(angle) * 57,
      );

      canvas.drawLine(start, end, tickPaint);
    }

    final handPaint = Paint()
      ..color = color
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(center.dx, center.dy - 40), handPaint);

    canvas.drawLine(center, Offset(center.dx + 32, center.dy + 22), handPaint);

    canvas.drawCircle(center, 7, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTRANCE
// ─────────────────────────────────────────────────────────────────────────────

class _FocusIllustration extends StatelessWidget {
  final double progress;

  const _FocusIllustration({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 260,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primaryContainer,
              border: Border.all(color: colors.primary, width: 12),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: .22),
                  blurRadius: 34,
                  spreadRadius: 3,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),

          Container(
            width: 147,
            height: 147,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface,
            ),
          ),

          Transform.rotate(
            angle: progress * .14,
            child: SizedBox(
              width: 125,
              height: 125,
              child: CustomPaint(painter: _ClockPainter(color: colors.primary)),
            ),
          ),

          Positioned(
            top: 17,
            right: 28,
            child: Transform.rotate(
              angle: -.25 + progress * .12,
              child: Icon(Icons.eco_rounded, size: 65, color: colors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GARDEN
// ─────────────────────────────────────────────────────────────────────────────

class _GardenIllustration extends StatelessWidget {
  final double progress;

  const _GardenIllustration({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 280,
      height: 270,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Soft background glow
          Positioned(
            bottom: 22,
            child: Container(
              width: 210,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: .13),
                    blurRadius: 55,
                    spreadRadius: 12,
                  ),
                ],
              ),
            ),
          ),

          // Ground shadow
          Positioned(
            bottom: 15,
            child: Container(
              width: 145,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: colors.primary.withValues(alpha: .09),
              ),
            ),
          ),

          // Pot
          Positioned(
            bottom: 30,
            child: CustomPaint(
              size: const Size(145, 105),
              painter: _GardenPotPainter(
                potColor: colors.primaryContainer,
                potHighlight: colors.secondaryContainer,
                soilColor: const Color(0xFF493225),
              ),
            ),
          ),

          // Plant
          Positioned(
            bottom: 115,
            child: Transform.scale(
              alignment: Alignment.bottomCenter,
              scale: .94 + (progress * .06),
              child: Transform.rotate(
                angle: (progress - .5) * .025,
                alignment: Alignment.bottomCenter,
                child: CustomPaint(
                  size: const Size(180, 145),
                  painter: _GardenPlantPainter(
                    progress: progress,
                    stemColor: const Color(0xFF22C55E),
                    leafLight: const Color(0xFF74E45D),
                    leafDark: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ),
          ),

          // Little sparkles around the plant
          Positioned(
            top: 38,
            left: 35,
            child: _GardenSparkle(
              size: 16,
              opacity: .45 + progress * .45,
              color: colors.primary,
            ),
          ),

          Positioned(
            top: 22,
            right: 42,
            child: _GardenSparkle(
              size: 22,
              opacity: .55 + progress * .4,
              color: const Color(0xFFFFC83D),
            ),
          ),

          Positioned(
            top: 86,
            right: 20,
            child: _GardenSparkle(
              size: 11,
              opacity: .35 + progress * .45,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GardenPlantPainter extends CustomPainter {
  final double progress;
  final Color stemColor;
  final Color leafLight;
  final Color leafDark;

  const _GardenPlantPainter({
    required this.progress,
    required this.stemColor,
    required this.leafLight,
    required this.leafDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = stemColor
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;

    // Main stem
    final stem = Path()
      ..moveTo(centerX, size.height)
      ..cubicTo(
        centerX - 2,
        size.height * .72,
        centerX + 3,
        size.height * .43,
        centerX,
        38,
      );

    canvas.drawPath(stem, stemPaint);

    // Branches
    canvas.drawLine(
      Offset(centerX, 88),
      Offset(centerX - 38, 62),
      stemPaint..strokeWidth = 5,
    );

    canvas.drawLine(
      Offset(centerX + 1, 72),
      Offset(centerX + 42, 43),
      stemPaint,
    );

    canvas.drawLine(
      Offset(centerX, 110),
      Offset(centerX - 32, 92),
      stemPaint..strokeWidth = 4,
    );

    // Left large leaf
    _drawLeaf(
      canvas,
      center: Offset(centerX - 48, 52),
      width: 77,
      height: 48,
      rotation: -.42,
      startColor: leafLight,
      endColor: leafDark,
    );

    // Right large leaf
    _drawLeaf(
      canvas,
      center: Offset(centerX + 52, 35),
      width: 88,
      height: 53,
      rotation: .38,
      startColor: leafLight,
      endColor: leafDark,
    );

    // Lower leaf
    _drawLeaf(
      canvas,
      center: Offset(centerX - 39, 88),
      width: 60,
      height: 36,
      rotation: -.25,
      startColor: leafLight,
      endColor: leafDark,
    );
  }

  @override
  bool shouldRepaint(covariant _GardenPlantPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.stemColor != stemColor ||
        oldDelegate.leafLight != leafLight ||
        oldDelegate.leafDark != leafDark;
  }

  void _drawLeaf(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required double rotation,
    required Color startColor,
    required Color endColor,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(-width / 2, 0)
      ..quadraticBezierTo(-width * .12, -height * .72, width / 2, 0)
      ..quadraticBezierTo(-width * .12, height * .72, -width / 2, 0)
      ..close();

    final bounds = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ).createShader(bounds),
    );

    // Leaf vein
    canvas.drawLine(
      Offset(-width * .32, 0),
      Offset(width * .32, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: .5)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
  }
}

class _GardenPotPainter extends CustomPainter {
  final Color potColor;
  final Color potHighlight;
  final Color soilColor;

  const _GardenPotPainter({
    required this.potColor,
    required this.potHighlight,
    required this.soilColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final potRect = Rect.fromLTWH(10, 14, size.width - 20, size.height - 18);

    final potPath = Path()
      ..moveTo(potRect.left, potRect.top)
      ..lineTo(potRect.right, potRect.top)
      ..lineTo(potRect.right - 18, potRect.bottom - 10)
      ..quadraticBezierTo(
        size.width / 2,
        potRect.bottom + 4,
        potRect.left + 18,
        potRect.bottom - 10,
      )
      ..close();

    final potPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [potHighlight, potColor],
      ).createShader(potRect);

    canvas.drawPath(potPath, potPaint);

    // Soft pot highlight
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: .18);

    final highlightPath = Path()
      ..moveTo(28, 30)
      ..quadraticBezierTo(35, 60, 30, size.height - 28);

    canvas.drawPath(
      highlightPath,
      highlightPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // Soil
    final soilRect = Rect.fromLTWH(8, 3, size.width - 16, 27);

    canvas.drawOval(soilRect, Paint()..color = soilColor);

    // Pot top rim
    canvas.drawOval(
      Rect.fromLTWH(5, 0, size.width - 10, 26),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = potHighlight,
    );
  }

  @override
  bool shouldRepaint(covariant _GardenPotPainter oldDelegate) {
    return oldDelegate.potColor != potColor ||
        oldDelegate.potHighlight != potHighlight ||
        oldDelegate.soilColor != soilColor;
  }
}

class _GardenSparkle extends StatelessWidget {
  final double size;
  final double opacity;
  final Color color;

  const _GardenSparkle({
    required this.size,
    required this.opacity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Icon(Icons.auto_awesome_rounded, size: size, color: color),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ILLUSTRATIONS
// ─────────────────────────────────────────────────────────────────────────────

class _Illustration extends StatelessWidget {
  final int page;
  final AnimationController lifeController;

  const _Illustration({required this.page, required this.lifeController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: lifeController,
      builder: (context, _) {
        final disableAnimations = MediaQuery.disableAnimationsOf(context);

        final t = disableAnimations
            ? .5
            : Curves.easeInOut.transform(lifeController.value);

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (page != 2) _BackgroundLeaves(progress: t, page: page),

            Positioned(
              top: 18 + (t * 4),
              left: 35,
              child: _Sparkle(size: 17, opacity: .4 + (t * .5)),
            ),

            Positioned(
              top: 45 - (t * 6),
              right: 42,
              child: _Sparkle(size: 25, opacity: .6 + (t * .4)),
            ),

            Transform.translate(
              offset: Offset(0, math.sin(t * math.pi) * -5),
              child: switch (page) {
                0 => _TasksIllustration(progress: t),
                1 => _FocusIllustration(progress: t),
                2 => _GardenIllustration(progress: t),
                _ => _ProgressIllustration(progress: t),
              },
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INDICATORS
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressIllustration extends StatelessWidget {
  final double progress;

  const _ProgressIllustration({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    const heights = [62.0, 92.0, 126.0, 166.0];

    return SizedBox(
      width: 270,
      height: 250,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 28,
            right: 28,
            bottom: 28,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          Positioned(
            left: 54,
            right: 54,
            bottom: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(heights.length, (index) {
                final pulse =
                    1 + (math.sin((progress + index * .12) * math.pi) * .025);

                return Transform.scale(
                  alignment: Alignment.bottomCenter,
                  scaleY: pulse,
                  child: Container(
                    width: 34,
                    height: heights[index],
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [colors.primary, colors.primaryContainer],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: .15),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          Positioned(
            right: 36,
            top: 2,
            child: Transform.rotate(
              angle: progress * .08,
              child: Icon(
                Icons.star_rounded,
                size: 62,
                color: const Color(0xFFFFC107),
              ),
            ),
          ),

          Positioned(
            top: 47,
            left: 55,
            child: Transform.rotate(
              angle: -.2,
              child: Icon(
                Icons.trending_up_rounded,
                size: 145,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final double size;
  final double opacity;

  const _Sparkle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Icon(
        Icons.auto_awesome_rounded,
        size: size,
        color: colors.primary,
      ),
    );
  }
}

class _Target extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primaryContainer,
              border: Border.all(color: colors.primary, width: 10),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: .22),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary, width: 9),
            ),
          ),
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary,
            ),
          ),
          Transform.rotate(
            angle: -.75,
            child: Transform.translate(
              offset: const Offset(0, -58),
              child: Icon(
                Icons.navigation_rounded,
                color: colors.secondary,
                size: 46,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TASKS
// ─────────────────────────────────────────────────────────────────────────────

class _TasksIllustration extends StatelessWidget {
  final double progress;

  const _TasksIllustration({required this.progress});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 280,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 28,
            top: 35,
            child: Transform.rotate(
              angle: -.05,
              child: Container(
                width: 150,
                height: 185,
                padding: const EdgeInsets.fromLTRB(20, 38, 20, 20),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: .28),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: .18),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    3,
                    (index) => Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colors.secondary.withAlpha(60),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 17,
                            color: colors.secondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 7,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: .3),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 74,
            top: 22,
            child: Container(
              width: 62,
              height: 27,
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.work_rounded,
                color: colors.onPrimary,
                size: 17,
              ),
            ),
          ),

          Positioned(
            right: 17,
            bottom: 13,
            child: Transform.scale(
              scale: .96 + (progress * .06),
              child: _Target(),
            ),
          ),
        ],
      ),
    );
  }
}
