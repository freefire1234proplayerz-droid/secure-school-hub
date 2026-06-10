import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography hierarchy for Secure School Hub (Material 3 type scale).
abstract final class AppTextStyles {
  static const String fontFamily = 'Roboto';
  static const String fontFamilyFallback = 'sans-serif';

  static TextTheme textTheme(ColorScheme colorScheme) {
    final base = Typography.material2021().black;
    final onSurface = colorScheme.onSurface;
    final onSurfaceVariant = colorScheme.onSurfaceVariant;

    return TextTheme(
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.1,
        color: onSurface,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.15,
        color: onSurface,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.2,
        color: onSurface,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        height: 1.25,
        color: onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.3,
        color: onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.35,
        color: onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.4,
        color: onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.45,
        color: onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.5,
        color: onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
        color: onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
        color: onSurface,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        height: 1.45,
        color: onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        height: 1.4,
        color: onSurface,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.35,
        color: onSurfaceVariant,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.3,
        color: onSurfaceVariant,
      ),
    ).apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );
  }

  /// Dashboard page title style.
  static TextStyle pageTitle(TextTheme theme) =>
      theme.headlineSmall!.copyWith(fontWeight: FontWeight.w800);

  /// Section heading inside dashboards.
  static TextStyle sectionTitle(TextTheme theme) =>
      theme.titleLarge!.copyWith(fontWeight: FontWeight.w800);

  /// Muted supporting copy.
  static TextStyle caption(TextTheme theme, ColorScheme scheme) =>
      theme.bodySmall!.copyWith(color: scheme.onSurfaceVariant);

  /// Accent link / CTA text.
  static TextStyle link(TextTheme theme, ColorScheme scheme) =>
      theme.labelLarge!.copyWith(
        color: scheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: scheme.primary.withValues(alpha: 0.6),
      );

  /// Metric value (large numeric display).
  static TextStyle metricValue(TextTheme theme) =>
      theme.headlineSmall!.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      );

  /// Overline / eyebrow label above headings.
  static TextStyle overline(ColorScheme scheme) => TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        height: 1.2,
        color: scheme.primary,
      );

  /// Semantic status styles.
  static TextStyle success(TextTheme theme) =>
      theme.labelMedium!.copyWith(color: AppColors.success);

  static TextStyle warning(TextTheme theme) =>
      theme.labelMedium!.copyWith(color: AppColors.warning);

  static TextStyle error(TextTheme theme) =>
      theme.labelMedium!.copyWith(color: AppColors.error);
}
