import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Animated unread badge with optional pulse for live notifications.
class MessageBadge extends StatefulWidget {
  const MessageBadge({
    super.key,
    required this.count,
    this.child,
    this.showPulse = false,
    this.compact = false,
  });

  final int count;
  final Widget? child;
  final bool showPulse;
  final bool compact;

  @override
  State<MessageBadge> createState() => _MessageBadgeState();
}

class _MessageBadgeState extends State<MessageBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.showPulse && widget.count > 0) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MessageBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulse && widget.count > 0 && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (widget.count == 0) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = widget.count > 99 ? '99+' : '${widget.count}';

    Widget badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 5 : 7,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: AppSpacing.borderRadiusXs,
        boxShadow: widget.showPulse
            ? [
                BoxShadow(
                  color: scheme.error.withValues(
                    alpha: 0.35 + 0.2 * (_pulse.value),
                  ),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onError,
              fontWeight: FontWeight.w800,
              fontSize: widget.compact ? 10 : 11,
            ),
      ),
    );

    if (widget.showPulse && widget.count > 0) {
      badge = AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Transform.scale(
          scale: 1.0 + 0.08 * _pulse.value,
          child: child,
        ),
        child: badge,
      );
    }

    if (widget.child == null) return badge;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child!,
        if (widget.count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: badge,
          ),
      ],
    );
  }
}

/// Small unread dot pulse indicator.
class UnreadPulse extends StatefulWidget {
  const UnreadPulse({super.key, this.color});

  final Color? color;

  @override
  State<UnreadPulse> createState() => _UnreadPulseState();
}

class _UnreadPulseState extends State<UnreadPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.85),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25 + 0.35 * _controller.value),
                blurRadius: 6 + 4 * _controller.value,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
