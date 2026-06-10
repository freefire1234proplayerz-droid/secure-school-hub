import 'package:flutter/material.dart';

/// Standard durations, curves, and reusable animation builders.
abstract final class AppAnimations {
  // ── Durations ────────────────────────────────────────────────────────────
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);
  static const Duration slower = Duration(milliseconds: 600);

  // ── Curves ───────────────────────────────────────────────────────────────
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve spring = Curves.elasticOut;

  // ── Page transitions ─────────────────────────────────────────────────────
  static Widget fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: enter),
      child: child,
    );
  }

  static Widget slideUpTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: enter));

    return SlideTransition(
      position: offset,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  // ── Stagger helpers ──────────────────────────────────────────────────────
  static Duration staggerDelay(int index, {Duration base = fast}) =>
      Duration(milliseconds: (base.inMilliseconds * 0.15 * index).round());

  static Animation<double> staggeredFade(
    AnimationController controller,
    int index, {
    int itemCount = 6,
  }) {
    final start = (index / itemCount) * 0.4;
    final end = start + 0.6;
    return CurvedAnimation(
      parent: controller,
      curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: enter),
    );
  }
}

/// Fade + slight slide-in on first build.
class AppFadeIn extends StatefulWidget {
  const AppFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppAnimations.normal,
    this.offset = const Offset(0, 12),
    this.curve = AppAnimations.enter,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  @override
  State<AppFadeIn> createState() => _AppFadeInState();
}

class _AppFadeInState extends State<AppFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slide = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: AnimatedBuilder(
        animation: _slide,
        builder: (context, child) => Transform.translate(
          offset: _slide.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Subtle scale pulse for loading / emphasis states.
class AppPulse extends StatefulWidget {
  const AppPulse({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
    this.minScale = 0.97,
    this.maxScale = 1.0,
  });

  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  @override
  State<AppPulse> createState() => _AppPulseState();
}

class _AppPulseState extends State<AppPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: widget.minScale, end: widget.maxScale)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}
