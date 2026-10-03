import 'package:flutter/material.dart';

class Achievement {
  final String id, title, description, metric;
  final int target;
  final IconData icon;
  const Achievement(
    this.id,
    this.title,
    this.description,
    this.metric,
    this.target,
    this.icon,
  );
  static const all = [
    Achievement(
      'focus_1',
      'First Focus',
      'Complete your first session.',
      'sessions',
      1,
      Icons.timer_rounded,
    ),
    Achievement(
      'focus_5',
      'Finding Flow',
      'Complete 5 sessions.',
      'sessions',
      5,
      Icons.waves_rounded,
    ),
    Achievement(
      'focus_10',
      'Deep Worker',
      'Complete 10 sessions.',
      'sessions',
      10,
      Icons.psychology_rounded,
    ),
    Achievement(
      'minutes_60',
      'One Hour',
      'Focus for 60 minutes in total.',
      'minutes',
      60,
      Icons.hourglass_bottom_rounded,
    ),
    Achievement(
      'minutes_600',
      'Ten Hours',
      'Focus for 10 hours in total.',
      'minutes',
      600,
      Icons.auto_awesome_rounded,
    ),
    Achievement(
      'tasks_1',
      'First Step',
      'Complete your first task.',
      'tasks',
      1,
      Icons.task_alt_rounded,
    ),
    Achievement(
      'tasks_10',
      'Getting Things Done',
      'Complete 10 distinct tasks.',
      'tasks',
      10,
      Icons.checklist_rounded,
    ),
    Achievement(
      'tasks_50',
      'Meaningful Work',
      'Complete 50 distinct tasks.',
      'tasks',
      50,
      Icons.verified_rounded,
    ),
    Achievement(
      'streak_3',
      'Growing Habit',
      'Focus on 3 consecutive days.',
      'streak',
      3,
      Icons.local_fire_department_rounded,
    ),
    Achievement(
      'streak_7',
      'A Focused Week',
      'Focus on 7 consecutive days.',
      'streak',
      7,
      Icons.park_rounded,
    ),
    Achievement(
      'streak_30',
      'Rooted in Focus',
      'Focus on 30 consecutive days.',
      'streak',
      30,
      Icons.forest_rounded,
    ),
  ];
}
