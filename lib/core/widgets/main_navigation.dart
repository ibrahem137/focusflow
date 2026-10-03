import '../../features/settings/ui/settings_screen.dart';
import '../../features/achievements/ui/achievements_screen.dart';

import 'package:flutter/material.dart';
import 'package:focus_flow/core/constants/theme/app_colors.dart';
import 'package:focus_flow/features/focus/ui/screens/focus_screen.dart';
import 'package:focus_flow/features/garden/ui/screens/garden_screen.dart';
import 'package:focus_flow/features/home/ui/screens/home_screen.dart';
import 'package:focus_flow/features/stats/ui/screens/stats_screen.dart';
import 'package:focus_flow/features/tasks/ui/screens/tasks_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  late final AnimationController _focusPulseController;

  late final Animation<double> _focusPulseAnimation;

  late final Animation<double> _focusGlowAnimation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final screens = [
      HomeScreen(
        isActive: _currentIndex == 0,

        onStartFocus: () {
          _changePage(2);
        },

        onSeeAllTasks: () {
          _changePage(1);
        },
      ),

      // مهم:

      // TasksScreen تعرف الآن إن كانت الشاشة ظاهرة أم لا.
      TasksScreen(isActive: _currentIndex == 1),

      FocusScreen(isActive: _currentIndex == 2),

      GardenScreen(isActive: _currentIndex == 3),

      StatsScreen(isActive: _currentIndex == 4),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text('FocusFlow'),
        actions: [
          IconButton(
            tooltip: 'Achievements',
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AchievementsScreen(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,

            children: List.generate(screens.length, (index) {
              final isActive = index == _currentIndex;

              return IgnorePointer(
                ignoring: !isActive,

                child: AnimatedOpacity(
                  opacity: isActive ? 1 : 0,

                  duration: const Duration(milliseconds: 260),

                  curve: Curves.easeOutCubic,

                  child: AnimatedSlide(
                    offset: isActive ? Offset.zero : const Offset(0.015, 0),

                    duration: const Duration(milliseconds: 300),

                    curve: Curves.easeOutCubic,

                    child: TickerMode(
                      enabled: isActive,
                      child: RepaintBoundary(child: screens[index]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          height: 72 + (MediaQuery.textScalerOf(context).scale(10) - 10) * 2,

          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),

          decoration: BoxDecoration(
            color: colorScheme.surface,

            borderRadius: BorderRadius.circular(24),

            border: Border.all(color: colorScheme.outlineVariant),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.18
                      : 0.06,
                ),

                blurRadius: 24,

                offset: const Offset(0, 8),
              ),
            ],
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [
              _navItem(
                context: context,

                index: 0,

                icon: Icons.home_rounded,

                label: 'Home',
              ),

              _navItem(
                context: context,

                index: 1,

                icon: Icons.check_circle_outline_rounded,

                label: 'Tasks',
              ),

              _buildFocusButton(context),

              _navItem(
                context: context,

                index: 3,

                icon: Icons.park_outlined,

                label: 'Garden',
              ),

              _navItem(
                context: context,

                index: 4,

                icon: Icons.bar_chart_rounded,

                label: 'Stats',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateFocusPulse();
  }

  @override
  void dispose() {
    _focusPulseController.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _focusPulseController = AnimationController(
      vsync: this,

      duration: const Duration(milliseconds: 1800),
    );

    _focusPulseAnimation = Tween<double>(begin: 1, end: 1.07).animate(
      CurvedAnimation(parent: _focusPulseController, curve: Curves.easeInOut),
    );

    _focusGlowAnimation = Tween<double>(begin: 0.18, end: 0.42).animate(
      CurvedAnimation(parent: _focusPulseController, curve: Curves.easeInOut),
    );
  }

  // ===========================================================================

  // Focus Button

  // ===========================================================================

  Widget _buildFocusButton(BuildContext context) {
    final isSelected = _currentIndex == 2;

    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTap: () {
        _changePage(2);
      },

      child: SizedBox(
        width: 68,

        height: 68,

        child: Center(
          child: AnimatedBuilder(
            animation: _focusPulseController,

            builder: (context, child) {
              final pulseScale = isSelected ? _focusPulseAnimation.value : 1.0;

              final glowOpacity = isSelected ? _focusGlowAnimation.value : 0.0;

              return Transform.scale(
                scale: pulseScale,

                child: Stack(
                  alignment: Alignment.center,

                  children: [
                    // Outer breathing glow

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),

                      width: isSelected ? 66 : 58,

                      height: isSelected ? 66 : 58,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: isSelected
                            ? AppColors.primary.withValues(
                                alpha: glowOpacity * 0.12,
                              )
                            : Colors.transparent,
                      ),
                    ),

                    // Main focus button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),

                      curve: Curves.easeOutCubic,

                      width: isSelected ? 58 : 54,

                      height: isSelected ? 58 : 54,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: isSelected
                            ? AppColors.primary
                            : colorScheme.surfaceContainerHighest,

                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : colorScheme.outlineVariant,
                        ),

                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: glowOpacity,
                                  ),

                                  blurRadius: 28,

                                  spreadRadius: 3,
                                ),
                              ]
                            : [],
                      ),

                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 300),

                        curve: Curves.easeOutBack,

                        scale: isSelected ? 1.08 : 1,

                        child: Icon(
                          Icons.timer_rounded,

                          color: isSelected
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,

                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===========================================================================

  // Navigation

  // ===========================================================================

  void _changePage(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    _updateFocusPulse();
  }

  // ===========================================================================

  // Normal Navigation Item

  // ===========================================================================

  Widget _navItem({
    required BuildContext context,

    required int index,

    required IconData icon,

    required String label,
  }) {
    final isSelected = _currentIndex == index;

    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: () {
        _changePage(index);
      },

      child: SizedBox(
        width: 52,

        height: 62 + (MediaQuery.textScalerOf(context).scale(10) - 10) * 2,

        child: Stack(
          alignment: Alignment.center,

          children: [
            AnimatedSlide(
              duration: const Duration(milliseconds: 280),

              curve: Curves.easeOutCubic,

              offset: isSelected ? const Offset(0, -0.04) : Offset.zero,

              child: AnimatedScale(
                scale: isSelected ? 1.08 : 1,

                duration: const Duration(milliseconds: 280),

                curve: Curves.easeOutBack,

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),

                      curve: Curves.easeOutCubic,

                      padding: EdgeInsets.all(isSelected ? 4 : 0),

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : Colors.transparent,
                      ),

                      child: Icon(
                        icon,

                        size: 23,

                        color: isSelected
                            ? AppColors.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 4),

                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),

                      curve: Curves.easeOutCubic,

                      style: TextStyle(
                        fontSize: 10,

                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,

                        color: isSelected
                            ? AppColors.primary
                            : colorScheme.onSurfaceVariant,
                      ),

                      child: Text(label),
                    ),
                  ],
                ),
              ),
            ),

            // Selected indicator
            Positioned(
              bottom: 2,

              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),

                curve: Curves.easeOutCubic,

                width: isSelected ? 16 : 0,

                height: 3,

                decoration: BoxDecoration(
                  color: AppColors.primary,

                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================

  // Focus Pulse

  // ===========================================================================

  void _updateFocusPulse() {
    if (_currentIndex == 2 && !MediaQuery.disableAnimationsOf(context)) {
      if (!_focusPulseController.isAnimating) {
        _focusPulseController.repeat(reverse: true);
      }
    } else {
      _focusPulseController.stop();

      _focusPulseController.reset();
    }
  }
}
