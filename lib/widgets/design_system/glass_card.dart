import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

enum GlassCardVariant { standard, elevated, flat }

/// Frosted-glass surface with blur, sheen, and optional shadow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin,
    this.borderRadius = AppSpacing.borderRadiusMd,
    this.variant = GlassCardVariant.standard,
    this.onTap,
    this.blur,
    this.tintColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final GlassCardVariant variant;
  final VoidCallback? onTap;
  final double? blur;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ext = AppThemeExtension.of(context);
    final brightness = theme.brightness;
    final effectiveBlur = blur ?? ext.glassBlur;

    final shadows = switch (variant) {
      GlassCardVariant.elevated => ext.elevatedCardShadow,
      GlassCardVariant.standard => ext.cardShadow,
      GlassCardVariant.flat => AppShadows.none,
    };

    final fill = tintColor ?? AppColors.glassFill(brightness);
    final borderColor = AppColors.glassBorder(brightness);

    Widget content = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: effectiveBlur,
          sigmaY: effectiveBlur,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: AppGradients.glassSheen(brightness),
            color: fill,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: shadows,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: scheme.primary.withValues(alpha: 0.08),
          highlightColor: scheme.primary.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}

/// Solid card using theme card styles (non-glass fallback).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.onTap,
    this.variant = GlassCardVariant.standard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final GlassCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final shadows = switch (variant) {
      GlassCardVariant.elevated => ext.elevatedCardShadow,
      GlassCardVariant.standard => ext.cardShadow,
      GlassCardVariant.flat => AppShadows.none,
    };

    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: shadows),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
