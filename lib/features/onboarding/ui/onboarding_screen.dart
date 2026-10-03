import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../settings/logic/settings_cubit.dart';

part 'widgets/onboarding_illustrations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
// DECORATION
// ─────────────────────────────────────────────────────────────────────────────

class _Entrance extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double offsetY;
  final double scaleFrom;

  const _Entrance({
    required this.animation,
    required this.child,
    required this.offsetY,
    required this.scaleFrom,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final value = animation.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - value)),
            child: Transform.scale(
              scale: scaleFrom + ((1 - scaleFrom) * value),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FOCUS
// ─────────────────────────────────────────────────────────────────────────────

class _Indicators extends StatelessWidget {
  final int currentPage;
  final int count;

  const _Indicators({required this.currentPage, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = currentPage == index;

        return Semantics(
          label: 'Page ${index + 1} of $count',
          selected: active,
          child: AnimatedContainer(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: active ? 10 : 8,
            height: active ? 10 : 8,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? colors.primary
                  : colors.primary.withValues(alpha: .18),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: .25),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;

  const _OnboardingData({required this.title, required this.description});
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final int index;
  final _OnboardingData data;
  final AnimationController entranceController;
  final AnimationController lifeController;

  const _OnboardingPage({
    required this.index,
    required this.data,
    required this.entranceController,
    required this.lifeController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final visualAnimation = entranceController.drive(
      CurveTween(curve: const Interval(0, .55, curve: Curves.easeOutBack)),
    );
    final titleAnimation = entranceController.drive(
      CurveTween(curve: const Interval(.25, .75, curve: Curves.easeOutCubic)),
    );
    final descriptionAnimation = entranceController.drive(
      CurveTween(curve: const Interval(.45, 1, curve: Curves.easeOutCubic)),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationHeight = math.min(constraints.maxHeight * .55, 350.0);

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: _Entrance(
                          animation: visualAnimation,
                          offsetY: 30,
                          scaleFrom: .88,
                          child: SizedBox(
                            width: double.infinity,
                            height: illustrationHeight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: 280,
                                height: 280,
                                child: _Illustration(
                                  page: index,
                                  lifeController: lifeController,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    _Entrance(
                      animation: titleAnimation,
                      offsetY: 22,
                      scaleFrom: .98,
                      child: Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.4,
                            ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _Entrance(
                      animation: descriptionAnimation,
                      offsetY: 18,
                      scaleFrom: 1,
                      child: Text(
                        data.description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 34),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  static const _pages = [
    _OnboardingData(
      title: 'Plan Meaningful Tasks',
      description:
          'Organize your day, set your goals\nand focus on what truly matters.',
    ),
    _OnboardingData(
      title: 'Focus Without Distractions',
      description: 'Use the timer, stay in the zone\nand get things done.',
    ),
    _OnboardingData(
      title: 'Grow Your Garden',
      description: 'The more you focus, the more\nyour garden grows.',
    ),
    _OnboardingData(
      title: 'Track Your Progress',
      description: 'See your achievements\nand become a better you.',
    ),
  ];

  final PageController _pageController = PageController();
  late final AnimationController _entranceController;

  late final AnimationController _lifeController;
  int _page = 0;

  bool _saving = false;
  bool _changingPage = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: _page == _pages.length - 1 ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: _page == _pages.length - 1,
                      child: TextButton(
                        onPressed: _saving ? null : _finish,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    index: index,
                    data: _pages[index],
                    entranceController: _entranceController,
                    lifeController: _lifeController,
                  );
                },
              ),
            ),

            _Indicators(currentPage: _page, count: _pages.length),

            const SizedBox(height: 26),

            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _saving || _changingPage ? null : _next,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _saving
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            key: ValueKey(_page),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _page == _pages.length - 1
                                    ? 'Get Started'
                                    : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_page != _pages.length - 1) ...[
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _lifeController.stop();
      _lifeController.value = .5;
      _entranceController.value = 1;
    } else if (!_lifeController.isAnimating) {
      _lifeController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    _lifeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _lifeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (MediaQuery.disableAnimationsOf(context)) {
        _entranceController.value = 1;
        _lifeController.value = .5;
      } else {
        _entranceController.forward();
        _lifeController.repeat(reverse: true);
      }
    });
  }

  Future<void> _finish() async {
    if (_saving) return;

    setState(() => _saving = true);

    await context.read<SettingsCubit>().set('onboarded', true);

    if (mounted) {
      setState(() => _saving = false);
    }
  }

  Future<void> _next() async {
    if (_saving || _changingPage) return;
    if (_page == _pages.length - 1) {
      await _finish();
      return;
    }

    if (MediaQuery.disableAnimationsOf(context)) {
      _pageController.jumpToPage(_page + 1);
      return;
    }
    setState(() => _changingPage = true);
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
    if (mounted) setState(() => _changingPage = false);
  }

  void _onPageChanged(int page) {
    setState(() => _page = page);

    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
      return;
    }

    _entranceController
      ..reset()
      ..forward();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROGRESS
// ─────────────────────────────────────────────────────────────────────────────
