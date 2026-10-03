import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;

  const _AnimatedBackground({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final value = controller.value;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + (value * 0.12), -1),
              end: Alignment(1, 1 - (value * 0.12)),
              colors: isDark
                  ? const [
                      Color(0xFF090711),
                      Color(0xFF120B24),
                      Color(0xFF071812),
                    ]
                  : const [
                      Color(0xFF28105F),
                      Color(0xFF4C1D95),
                      Color(0xFF123B2A),
                    ],
            ),
          ),
          child: CustomPaint(
            painter: _BackgroundPainter(animationValue: value, isDark: isDark),
          ),
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  _BackgroundPainter({required this.animationValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = (math.sin(animationValue * math.pi) + 1) / 2;

    final purplePaint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(
        alpha: isDark ? 0.09 + (pulse * 0.04) : 0.13 + (pulse * 0.05),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.24),
      size.width * (0.32 + pulse * 0.03),
      purplePaint,
    );

    final greenPaint = Paint()
      ..color = const Color(0xFF22C55E).withValues(
        alpha: isDark ? 0.06 + (pulse * 0.025) : 0.08 + (pulse * 0.035),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);

    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.72),
      size.width * (0.28 + pulse * 0.025),
      greenPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isDark != isDark;
  }
}

class _ClockPainter extends CustomPainter {
  final double progress;

  _ClockPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 7),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      ringPaint,
    );

    if (progress < 0.55) return;

    final handProgress = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);

    final handPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final minuteEnd = Offset(center.dx, center.dy - (31 * handProgress));

    canvas.drawLine(center, minuteEnd, handPaint);

    if (handProgress > 0.45) {
      final secondProgress = ((handProgress - 0.45) / 0.55).clamp(0.0, 1.0);

      final target = Offset(center.dx + 26, center.dy + 20);

      canvas.drawLine(
        center,
        Offset.lerp(center, target, secondProgress)!,
        handPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _FocusFlowLogo extends StatelessWidget {
  final double clockProgress;
  final double leafScale;
  final double lifeValue;

  const _FocusFlowLogo({
    required this.clockProgress,
    required this.leafScale,
    required this.lifeValue,
  });

  @override
  Widget build(BuildContext context) {
    final glow = (math.sin(lifeValue * math.pi) + 1) / 2;

    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 176 + glow * 6,
            height: 176 + glow * 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6)
                      .withValues(alpha: 0.20 + glow * 0.10),
                  blurRadius: 52 + glow * 12,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),

          Container(
            width: 164,
            height: 164,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(46),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFB85CFF),
                  Color(0xFF7C3AED),
                  Color(0xFF4F20F3),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(-4, -4),
                ),
              ],
            ),
          ),

          SizedBox(
            width: 115,
            height: 115,
            child: CustomPaint(painter: _ClockPainter(progress: clockProgress)),
          ),

          Positioned(
            top: 13,
            right: 12,
            child: Transform.scale(
              scale: leafScale,
              child: Transform.rotate(
                angle: -0.48,
                child: const _Leaf(width: 61, height: 34),
              ),
            ),
          ),

          Positioned(
            top: 42,
            left: 17,
            child: Transform.scale(
              scale: leafScale * 0.72,
              child: Transform.rotate(
                angle: 0.52,
                child: const _Leaf(width: 31, height: 18),
              ),
            ),
          ),

          Positioned(
            right: 13,
            bottom: 40,
            child: Transform.scale(
              scale: leafScale * 0.62,
              child: Transform.rotate(
                angle: -0.55,
                child: const _Leaf(width: 29, height: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Leaf extends StatelessWidget {
  final double width;
  final double height;

  const _Leaf({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(height),
          bottomRight: Radius.circular(height),
          topRight: Radius.circular(height * 0.35),
          bottomLeft: Radius.circular(height * 0.35),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8CF45B), Color(0xFF22C55E), Color(0xFF00A86B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.28),
            blurRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: Transform.rotate(
          angle: -0.05,
          child: Container(
            width: width * 0.55,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _lifeController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _clockProgress;
  late final Animation<double> _leafScale;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineOpacity;

  bool _finished = false;
  Timer? _finishTimer;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF090711),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AnimatedBackground(controller: _lifeController, isDark: isDark),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _introController,
                          _lifeController,
                        ]),
                        builder: (context, _) {
                          final pulse = 1 + (_lifeController.value * 0.025);

                          return Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: _logoScale.value * pulse,
                              child: _FocusFlowLogo(
                                clockProgress: _clockProgress.value,
                                leafScale: _leafScale.value,
                                lifeValue: _lifeController.value,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 36),

                      FadeTransition(
                        opacity: _titleOpacity,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: const Text(
                            'FocusFlow',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      FadeTransition(
                        opacity: _taglineOpacity,
                        child: Text(
                          'Focus deeply. Grow every day.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 14,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _introController.dispose();
    _lifeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    );

    _lifeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );

    _clockProgress = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.15, 0.58, curve: Curves.easeInOutCubic),
    );

    _leafScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.42, 0.72, curve: Curves.elasticOut),
      ),
    );

    _titleOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.58, 0.82, curve: Curves.easeOut),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.58, 0.82, curve: Curves.easeOutCubic),
          ),
        );

    _taglineOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.72, 0.94, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Give Flutter one complete visible frame before starting the intro.
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      _startAnimation();
    });
  }

  void _finish() {
    if (!mounted || _finished) return;

    _finished = true;
    widget.onFinished();
  }

  Future<void> _startAnimation() async {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      _introController.value = 1;
      _lifeController.value = .5;
      _finishTimer = Timer(const Duration(milliseconds: 450), _finish);
      return;
    }

    _lifeController.repeat(reverse: true);

    try {
      await _introController.forward().orCancel;
      if (mounted) {
        _lifeController.stop();
        _finishTimer = Timer(const Duration(milliseconds: 250), _finish);
      }
    } on TickerCanceled {
      // Normal when the application is closed during the intro.
    }
  }
}
