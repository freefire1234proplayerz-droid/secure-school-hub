import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, glass, danger }

enum AppButtonSize { sm, md, lg }

/// Unified button component with glass and gradient variants.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  double get _height => switch (size) {
        AppButtonSize.sm => AppSpacing.buttonHeightSm,
        AppButtonSize.md => AppSpacing.buttonHeightMd,
        AppButtonSize.lg => AppSpacing.buttonHeightLg,
      };

  EdgeInsets get _padding => switch (size) {
        AppButtonSize.sm => const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
        AppButtonSize.md => const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        AppButtonSize.lg => const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final enabled = onPressed != null && !isLoading;

    final child = _buildChild(context);

    Widget button = switch (variant) {
      AppButtonVariant.primary => _GradientButton(
          onPressed: enabled ? onPressed : null,
          gradient: AppGradients.heroAccent(scheme),
          glow: AppShadows.primaryGlow(scheme.primary),
          height: _height,
          padding: _padding,
          foreground: scheme.onPrimary,
          child: child,
        ),
      AppButtonVariant.secondary => FilledButton.tonal(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            minimumSize: Size(expand ? double.infinity : 88, _height),
            padding: _padding,
          ),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(expand ? double.infinity : 88, _height),
            padding: _padding,
          ),
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            minimumSize: Size(expand ? double.infinity : 64, _height),
            padding: _padding,
          ),
          child: child,
        ),
      AppButtonVariant.glass => _GlassButton(
          onPressed: enabled ? onPressed : null,
          height: _height,
          padding: _padding,
          brightness: brightness,
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            minimumSize: Size(expand ? double.infinity : 88, _height),
            padding: _padding,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: child,
        ),
    };

    if (expand && variant != AppButtonVariant.primary) {
      button = SizedBox(width: double.infinity, child: button);
    }

    if (expand && variant == AppButtonVariant.primary) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.55,
      duration: AppAnimations.fast,
      child: button,
    );
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      final color = switch (variant) {
        AppButtonVariant.primary || AppButtonVariant.danger =>
          Theme.of(context).colorScheme.onPrimary,
        _ => Theme.of(context).colorScheme.primary,
      };
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }

    final text = Text(label);
    if (icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSpacing.iconSm),
        const SizedBox(width: AppSpacing.xs),
        text,
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onPressed,
    required this.gradient,
    required this.glow,
    required this.height,
    required this.padding,
    required this.foreground,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Gradient gradient;
  final List<BoxShadow> glow;
  final double height;
  final EdgeInsets padding;
  final Color foreground;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: onPressed != null ? glow : null,
        gradient: onPressed != null ? gradient : null,
        color: onPressed == null
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Container(
            constraints: BoxConstraints(minHeight: height),
            padding: padding,
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: onPressed != null
                        ? foreground
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              child: IconTheme(
                data: IconThemeData(
                  color: onPressed != null
                      ? foreground
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: AppSpacing.iconSm,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.onPressed,
    required this.height,
    required this.padding,
    required this.brightness,
    required this.child,
  });

  final VoidCallback? onPressed;
  final double height;
  final EdgeInsets padding;
  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.borderRadiusMd,
        gradient: AppGradients.glassSheen(brightness),
        border: Border.all(
          color: AppColors.glassBorder(brightness),
        ),
        boxShadow: AppShadows.sm(brightness),
      ),
      child: Material(
        color: AppColors.glassFill(brightness),
        borderRadius: AppSpacing.borderRadiusMd,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppSpacing.borderRadiusMd,
          child: Container(
            constraints: BoxConstraints(minHeight: height),
            padding: padding,
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: scheme.onSurface,
                  ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
