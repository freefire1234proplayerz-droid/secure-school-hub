import 'package:flutter/material.dart';

/// Brand and semantic colors for Secure School Hub.
/// Use [AppColors] for static tokens; prefer [ColorScheme] from theme in widgets.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF3D5AFE);
  static const Color primaryDark = Color(0xFF2A3EB1);
  static const Color primaryLight = Color(0xFF7C8FFF);

  static const Color secondary = Color(0xFF00BFA5);
  static const Color secondaryDark = Color(0xFF008E76);
  static const Color secondaryLight = Color(0xFF5DF2D6);

  static const Color tertiary = Color(0xFFFFB300);
  static const Color tertiaryDark = Color(0xFFC68400);
  static const Color tertiaryLight = Color(0xFFFFE082);

  // ── Neutrals ───────────────────────────────────────────────────────────
  static const Color neutral950 = Color(0xFF0B0F1A);
  static const Color neutral900 = Color(0xFF111827);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral50 = Color(0xFFF9FAFB);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);

  static const Color error = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFFFEE2E2);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // ── Glass surfaces ─────────────────────────────────────────────────────
  static const Color glassLight = Color(0xB8FFFFFF);
  static const Color glassLightBorder = Color(0x66FFFFFF);
  static const Color glassDark = Color(0x9920283A);
  static const Color glassDarkBorder = Color(0x4DFFFFFF);

  /// Light-mode Material 3 color scheme with brand overrides.
  static ColorScheme lightScheme() {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    );
    return base.copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDDE3FF),
      onPrimaryContainer: primaryDark,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFB2F5EA),
      onSecondaryContainer: secondaryDark,
      tertiary: tertiary,
      onTertiary: neutral900,
      tertiaryContainer: const Color(0xFFFFECB3),
      onTertiaryContainer: tertiaryDark,
      surface: neutral50,
      onSurface: neutral900,
      surfaceContainerHighest: neutral200,
      onSurfaceVariant: neutral600,
      outline: neutral300,
      outlineVariant: neutral200,
      error: error,
      onError: Colors.white,
      errorContainer: errorContainer,
      onErrorContainer: const Color(0xFF991B1B),
    );
  }

  /// Dark-mode Material 3 color scheme with brand overrides.
  static ColorScheme darkScheme() {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      primary: primaryLight,
      onPrimary: neutral950,
      primaryContainer: primaryDark,
      onPrimaryContainer: const Color(0xFFDDE3FF),
      secondary: secondaryLight,
      onSecondary: neutral950,
      secondaryContainer: secondaryDark,
      onSecondaryContainer: const Color(0xFFB2F5EA),
      tertiary: tertiaryLight,
      onTertiary: neutral950,
      tertiaryContainer: tertiaryDark,
      onTertiaryContainer: const Color(0xFFFFECB3),
      surface: neutral950,
      onSurface: neutral100,
      surfaceContainerHighest: neutral800,
      onSurfaceVariant: neutral400,
      outline: neutral700,
      outlineVariant: neutral800,
      error: const Color(0xFFF87171),
      onError: neutral950,
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFECACA),
    );
  }

  /// Resolves glass fill color from brightness.
  static Color glassFill(Brightness brightness) =>
      brightness == Brightness.dark ? glassDark : glassLight;

  /// Resolves glass border color from brightness.
  static Color glassBorder(Brightness brightness) =>
      brightness == Brightness.dark ? glassDarkBorder : glassLightBorder;
}
