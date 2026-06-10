import 'package:flutter/material.dart';

import '../../theme/app_gradients.dart';

/// Full-screen gradient backdrop for dashboards and auth screens.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.gradient,
    this.showOrbs = true,
  });

  final Widget child;
  final Gradient? gradient;
  final bool showOrbs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final pageGradient =
        gradient ?? AppGradients.pageBackground(scheme, brightness);

    return DecoratedBox(
      decoration: BoxDecoration(gradient: pageGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (showOrbs) ..._orbLayer(scheme, brightness),
          child,
        ],
      ),
    );
  }

  List<Widget> _orbLayer(ColorScheme scheme, Brightness brightness) {
    final primaryAlpha = brightness == Brightness.dark ? 0.18 : 0.22;
    final secondaryAlpha = brightness == Brightness.dark ? 0.12 : 0.16;

    return [
      Positioned(
        top: -80,
        right: -40,
        child: _GradientOrb(
          size: 220,
          color: scheme.primary.withValues(alpha: primaryAlpha),
        ),
      ),
      Positioned(
        bottom: -60,
        left: -50,
        child: _GradientOrb(
          size: 180,
          color: scheme.secondary.withValues(alpha: secondaryAlpha),
        ),
      ),
      Positioned(
        top: 180,
        left: -30,
        child: _GradientOrb(
          size: 120,
          color: scheme.tertiary.withValues(alpha: secondaryAlpha * 0.8),
        ),
      ),
    ];
  }
}

class _GradientOrb extends StatelessWidget {
  const _GradientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
