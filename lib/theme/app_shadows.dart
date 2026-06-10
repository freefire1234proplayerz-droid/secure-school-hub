import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevation and glow shadows for cards, glass surfaces, and floating elements.
abstract final class AppShadows {
  static List<BoxShadow> none = const [];

  static List<BoxShadow> xs(Brightness brightness) => [
        BoxShadow(
          color: _shadowColor(brightness, 0.06),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> sm(Brightness brightness) => [
        BoxShadow(
          color: _shadowColor(brightness, 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: _shadowColor(brightness, 0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> md(Brightness brightness) => [
        BoxShadow(
          color: _shadowColor(brightness, 0.10),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: _shadowColor(brightness, 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> lg(Brightness brightness) => [
        BoxShadow(
          color: _shadowColor(brightness, 0.14),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: _shadowColor(brightness, 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> xl(Brightness brightness) => [
        BoxShadow(
          color: _shadowColor(brightness, 0.18),
          blurRadius: 40,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: _shadowColor(brightness, 0.10),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Soft inner glow for glass cards.
  static List<BoxShadow> glassInner(Brightness brightness) => [
        BoxShadow(
          color: brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.55),
          blurRadius: 0,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ];

  /// Colored glow for primary CTAs and focus states.
  static List<BoxShadow> primaryGlow(Color primary) => [
        BoxShadow(
          color: primary.withValues(alpha: 0.35),
          blurRadius: 20,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ];

  static Color shadowColor(Brightness brightness, double opacity) {
    return brightness == Brightness.dark
        ? Colors.black.withValues(alpha: opacity * 1.6)
        : AppColors.neutral900.withValues(alpha: opacity);
  }

  static Color _shadowColor(Brightness brightness, double opacity) =>
      shadowColor(brightness, opacity);
}
