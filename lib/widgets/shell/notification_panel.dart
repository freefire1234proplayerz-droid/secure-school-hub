import 'package:flutter/material.dart';

import '../../theme/app_animations.dart' show AppAnimations, AppFadeIn;
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'shell_models.dart';

/// Slide-over notification center UI.
class NotificationPanel extends StatelessWidget {
  const NotificationPanel({
    super.key,
    required this.notifications,
    this.onClose,
    this.onMarkAllRead,
  });

  final List<ShellNotification> notifications;
  final VoidCallback? onClose;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unread = notifications.where((n) => n.isUnread).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.hasBoundedWidth && constraints.maxWidth.isFinite
                ? constraints.maxWidth.clamp(0.0, 360.0).toDouble()
                : 360.0;

        return Material(
          elevation: 12,
          shadowColor: scheme.shadow.withValues(alpha: 0.2),
          borderRadius: AppSpacing.borderRadiusLg,
          color: scheme.surface.withValues(alpha: 0.98),
          child: SizedBox(
            width: maxWidth,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              if (unread > 0)
                                Text(
                                  '$unread unread',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: scheme.primary,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        if (onMarkAllRead != null && unread > 0)
                          TextButton(
                            onPressed: onMarkAllRead,
                            child: const Text('Mark all read'),
                          ),
                        if (onClose != null)
                          IconButton(
                            tooltip: 'Close',
                            onPressed: onClose,
                            icon: const Icon(Icons.close_rounded),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: notifications.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 40,
                                    color: scheme.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'All caught up',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  Text(
                                    'No new notifications',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.xs),
                            itemBuilder: (context, index) {
                              final n = notifications[index];
                              return AppFadeIn(
                                delay: AppAnimations.staggerDelay(
                                  index,
                                  base: AppAnimations.instant,
                                ),
                                offset: const Offset(0, 6),
                                child: _NotificationTile(notification: n),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final ShellNotification notification;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      variant: GlassCardVariant.flat,
      padding: const EdgeInsets.all(AppSpacing.sm),
      tintColor: notification.isUnread
          ? notification.color.withValues(alpha: 0.06)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: notification.color.withValues(alpha: 0.14),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(notification.icon, color: notification.color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (notification.time != null)
                      Text(
                        notification.time!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (notification.isUnread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

/// Notification bell button with unread badge.
class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: 'Notifications',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
        backgroundColor: scheme.error,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
