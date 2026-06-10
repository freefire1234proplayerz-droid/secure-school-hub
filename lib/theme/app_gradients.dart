import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared gradient presets for backgrounds, cards, and accents.
abstract final class AppGradients {
  // ── Page backgrounds ───────────────────────────────────────────────────
  static LinearGradient pageBackgroundLight(ColorScheme scheme) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.primaryContainer.withValues(alpha: 0.55),
          scheme.surface,
          scheme.secondaryContainer.withValues(alpha: 0.35),
        ],
        stops: const [0.0, 0.45, 1.0],
      );

  static LinearGradient pageBackgroundDark(ColorScheme scheme) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.neutral950,
          scheme.primaryContainer.withValues(alpha: 0.22),
          AppColors.neutral900,
          scheme.secondaryContainer.withValues(alpha: 0.12),
        ],
        stops: const [0.0, 0.3, 0.65, 1.0],
      );

  // ── Hero / header accents ────────────────────────────────────────────────
  static LinearGradient heroAccent(ColorScheme scheme) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.primary,
          scheme.secondary,
        ],
      );

  static LinearGradient heroAccentSoft(ColorScheme scheme) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.primary.withValues(alpha: 0.85),
          scheme.secondary.withValues(alpha: 0.75),
        ],
      );

  // ── Glass card overlays ──────────────────────────────────────────────────
  static LinearGradient glassSheen(Brightness brightness) =>
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: brightness == Brightness.dark
            ? [
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.04),
                Colors.transparent,
              ]
            : [
                Colors.white.withValues(alpha: 0.72),
                Colors.white.withValues(alpha: 0.28),
                Colors.white.withValues(alpha: 0.08),
              ],
        stops: const [0.0, 0.35, 1.0],
      );

  static LinearGradient glassBorder(Brightness brightness) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: brightness == Brightness.dark
            ? [
                Colors.white.withValues(alpha: 0.35),
                Colors.white.withValues(alpha: 0.08),
              ]
            : [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.35),
              ],
      );

  // ── Semantic status gradients ────────────────────────────────────────────
  static const LinearGradient success = LinearGradient(
    colors: [AppColors.success, Color(0xFF059669)],
  );

  static const LinearGradient warning = LinearGradient(
    colors: [AppColors.warning, Color(0xFFD97706)],
  );

  static const LinearGradient error = LinearGradient(
    colors: [AppColors.error, Color(0xFFDC2626)],
  );

  static const LinearGradient info = LinearGradient(
    colors: [AppColors.info, Color(0xFF2563EB)],
  );

  // ── Chart / data visualization ───────────────────────────────────────────
  static LinearGradient chartFill(ColorScheme scheme) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scheme.primary.withValues(alpha: 0.28),
          scheme.primary.withValues(alpha: 0.02),
        ],
      );

  /// Resolves the appropriate page background for the current brightness.
  static LinearGradient pageBackground(
    ColorScheme scheme,
    Brightness brightness,
  ) =>
      brightness == Brightness.dark
          ? pageBackgroundDark(scheme)
          : pageBackgroundLight(scheme);
}
