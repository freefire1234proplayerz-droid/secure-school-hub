import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_animations.dart';
import 'app_colors.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Central theme configuration for Secure School Hub (Material 3).
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark ? AppColors.darkScheme() : AppColors.lightScheme();
    final textTheme = AppTextStyles.textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _AppPageTransitionsBuilder(),
          TargetPlatform.iOS: _AppPageTransitionsBuilder(),
          TargetPlatform.macOS: _AppPageTransitionsBuilder(),
          TargetPlatform.linux: _AppPageTransitionsBuilder(),
          TargetPlatform.windows: _AppPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _AppPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface.withValues(alpha: isDark ? 0.72 : 0.88),
        shadowColor: AppShadows.shadowColor(brightness, 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(scheme, textTheme),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(scheme, textTheme),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(scheme, textTheme),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(scheme, textTheme),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          visualDensity: VisualDensity.standard,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusSm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.45 : 0.65,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
        ),
        backgroundColor: isDark ? scheme.inverseSurface : scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: scheme.surface.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: scheme.surface.withValues(alpha: 0.96),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        showDragHandle: true,
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
        labelStyle: textTheme.labelMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
        ),
      ),
      extensions: [
        AppThemeExtension(
          brightness: brightness,
          glassBlur: isDark ? 18 : 14,
          cardShadow: AppShadows.md(brightness),
          elevatedCardShadow: AppShadows.lg(brightness),
          pageGradient: brightness == Brightness.dark
              ? null // resolved at runtime via AppGradients + ColorScheme
              : null,
        ),
      ],
    );
  }

  static ButtonStyle _filledButtonStyle(
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return FilledButton.styleFrom(
      minimumSize: const Size(88, AppSpacing.buttonHeightMd),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      elevation: 0,
      textStyle: textTheme.labelLarge,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return scheme.onPrimary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return scheme.onPrimary.withValues(alpha: 0.08);
        }
        return null;
      }),
    );
  }

  static ButtonStyle _outlinedButtonStyle(
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return OutlinedButton.styleFrom(
      minimumSize: const Size(88, AppSpacing.buttonHeightMd),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      textStyle: textTheme.labelLarge,
      side: BorderSide(color: scheme.outline.withValues(alpha: 0.8)),
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
      ),
    );
  }

  static ButtonStyle _textButtonStyle(
    ColorScheme scheme,
    TextTheme textTheme,
  ) {
    return TextButton.styleFrom(
      minimumSize: const Size(64, AppSpacing.buttonHeightSm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      textStyle: textTheme.labelLarge?.copyWith(color: scheme.primary),
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusSm,
      ),
    );
  }
}

/// Theme extension exposing design-system tokens to widgets.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.brightness,
    required this.glassBlur,
    required this.cardShadow,
    required this.elevatedCardShadow,
    this.pageGradient,
  });

  final Brightness brightness;
  final double glassBlur;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> elevatedCardShadow;
  final Gradient? pageGradient;

  bool get isDark => brightness == Brightness.dark;

  static AppThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<AppThemeExtension>()!;
  }

  @override
  AppThemeExtension copyWith({
    Brightness? brightness,
    double? glassBlur,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? elevatedCardShadow,
    Gradient? pageGradient,
  }) {
    return AppThemeExtension(
      brightness: brightness ?? this.brightness,
      glassBlur: glassBlur ?? this.glassBlur,
      cardShadow: cardShadow ?? this.cardShadow,
      elevatedCardShadow: elevatedCardShadow ?? this.elevatedCardShadow,
      pageGradient: pageGradient ?? this.pageGradient,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      brightness: t < 0.5 ? brightness : other.brightness,
      glassBlur: lerpDouble(glassBlur, other.glassBlur, t) ?? glassBlur,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      elevatedCardShadow:
          t < 0.5 ? elevatedCardShadow : other.elevatedCardShadow,
      pageGradient: t < 0.5 ? pageGradient : other.pageGradient,
    );
  }
}

class _AppPageTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AppAnimations.slideUpTransition(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
