import 'package:flutter/material.dart';

abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand - Shared
  // ---------------------------------------------------------------------------

  static const Color primary = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFF22C55E);

  // ---------------------------------------------------------------------------
  // Dark Theme
  // ---------------------------------------------------------------------------

  static const Color background = Color(0xFF0B0B0F);
  static const Color surface = Color(0xFF15151C);
  static const Color surfaceLight = Color(0xFF1D1D27);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF9CA3AF);

  static const Color divider = Color(0xFF27272F);

  // ---------------------------------------------------------------------------
  // Light Theme
  // ---------------------------------------------------------------------------

  static const Color lightBackground = Color(0xFFF7F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F0F7);

  static const Color lightTextPrimary = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF71717A);

  static const Color lightDivider = Color(0xFFE4E4E7);

  // ---------------------------------------------------------------------------
  // Status - Shared
  // ---------------------------------------------------------------------------

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
}
