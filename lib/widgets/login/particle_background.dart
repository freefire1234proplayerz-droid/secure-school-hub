import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/app_gradients.dart';

/// Animated gradient backdrop with drifting particle dots.
class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key, required this.child});

  final Widget child;

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: _animatedGradient(scheme, brightness, t),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: _ParticlePainter(
                  progress: t,
                  primary: scheme.primary,
                  secondary: scheme.secondary,
                  tertiary: scheme.tertiary,
                  brightness: brightness,
                ),
              ),
              _GlowOrbs(scheme: scheme, progress: t),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }

  LinearGradient _animatedGradient(
    ColorScheme scheme,
    Brightness brightness,
    double t,
  ) {
    final base = AppGradients.pageBackground(scheme, brightness);
    final shift = math.sin(t * math.pi * 2) * 0.08;
    return LinearGradient(
      begin: Alignment(-1 + shift, -1),
      end: Alignment(1 - shift, 1),
      colors: base.colors,
      stops: base.stops,
    );
  }
}

class _GlowOrbs extends StatelessWidget {
  const _GlowOrbs({required this.scheme, required this.progress});

  final ColorScheme scheme;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final drift = math.sin(progress * math.pi * 2);

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -60 + drift * 24,
            right: -30,
            child: _orb(scheme.primary.withValues(alpha: 0.2), 240),
          ),
          Positioned(
            bottom: -40 - drift * 18,
            left: -50,
            child: _orb(scheme.secondary.withValues(alpha: 0.16), 200),
          ),
          Positioned(
            top: 200 + drift * 12,
            left: MediaQuery.sizeOf(context).width * 0.35,
            child: _orb(scheme.tertiary.withValues(alpha: 0.1), 140),
          ),
        ],
      ),
    );
  }

  Widget _orb(Color color, double size) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.brightness,
  });

  final double progress;
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Brightness brightness;

  static const _count = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final alpha = brightness == Brightness.dark ? 0.35 : 0.28;

    for (var i = 0; i < _count; i++) {
      final seed = i / _count;
      final xBase = rng.nextDouble() * size.width;
      final yBase = rng.nextDouble() * size.height;
      final radius = 1.2 + rng.nextDouble() * 2.2;
      final speed = 0.3 + rng.nextDouble() * 0.7;

      final x = (xBase + math.sin((progress + seed) * math.pi * 2) * 28 * speed) %
          size.width;
      final y = (yBase + math.cos((progress + seed) * math.pi * 2) * 22 * speed) %
          size.height;

      final color = switch (i % 3) {
        0 => primary,
        1 => secondary,
        _ => tertiary,
      };

      final paint = Paint()
        ..color = color.withValues(alpha: alpha * (0.4 + seed * 0.6))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
