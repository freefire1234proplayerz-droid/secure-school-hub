import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'dashboard_components.dart';
import 'empty_state.dart';

/// Glass-wrapped activity / notification timeline.
class ActivityFeedCard extends StatelessWidget {
  const ActivityFeedCard({
    super.key,
    required this.items,
    this.title,
    this.emptyTitle = 'No activity yet',
    this.emptyMessage = 'Updates will appear here as they happen.',
    this.emptyIcon = Icons.inbox_outlined,
  });

  final List<DashboardNotification> items;
  final String? title;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (items.isEmpty)
            DashboardEmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              message: emptyMessage,
              compact: true,
            )
          else
            ...[
              for (var i = 0; i < items.length; i++) ...[
                AppFadeIn(
                  delay: AppAnimations.staggerDelay(i, base: AppAnimations.instant),
                  offset: const Offset(8, 0),
                  child: _TimelineTile(
                    item: items[i],
                    isLast: i == items.length - 1,
                  ),
                ),
                if (i != items.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.item, required this.isLast});

  final DashboardNotification item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.14),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(item.icon, color: item.color, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (item.time != null)
                        Text(
                          item.time!,
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.detail,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
