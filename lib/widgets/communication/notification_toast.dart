import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'communication_models.dart';

/// Slide-in live notification toast overlay.
class NotificationToast extends StatefulWidget {
  const NotificationToast({
    super.key,
    required this.notice,
    required this.onDismiss,
    this.onTap,
  });

  final NoticeItem notice;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  @override
  State<NotificationToast> createState() => _NotificationToastState();
}

class _NotificationToastState extends State<NotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );
    _slide = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppAnimations.emphasized));
    _controller.forward();
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (mounted) _dismiss();
    });
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.notice.priority.color(scheme);

    return SlideTransition(
      position: _slide,
      child: Material(
        color: Colors.transparent,
        child: GlassCard(
          onTap: widget.onTap,
          variant: GlassCardVariant.elevated,
          tintColor: color.withValues(alpha: 0.08),
          margin: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(widget.notice.category.icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.notice.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      widget.notice.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: _dismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Manages stacked notification toasts at the top of the screen.
class NotificationToastHost extends StatefulWidget {
  const NotificationToastHost({super.key, required this.child});

  final Widget child;

  static NotificationToastHostState? of(BuildContext context) {
    return context.findAncestorStateOfType<NotificationToastHostState>();
  }

  @override
  State<NotificationToastHost> createState() => NotificationToastHostState();
}

class NotificationToastHostState extends State<NotificationToastHost> {
  final List<NoticeItem> _toasts = [];

  void showToast(NoticeItem notice) {
    setState(() => _toasts.insert(0, notice));
  }

  void _remove(String id) {
    setState(() => _toasts.removeWhere((n) => n.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.paddingOf(context).top + 64,
          right: 0,
          left: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final toast in _toasts.take(3))
                SizedBox(
                  width: 380,
                  child: NotificationToast(
                    notice: toast,
                    onDismiss: () => _remove(toast.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
