import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'communication_models.dart';

/// Real-time activity stream / announcement timeline.
class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({
    super.key,
    required this.items,
    this.title = 'Activity stream',
    this.groupByDate = true,
    this.emptyMessage = 'No recent activity.',
  });

  final List<ActivityStreamItem> items;
  final String title;
  final bool groupByDate;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return GlassCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              emptyMessage,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final grouped = groupByDate ? _groupByDay(items) : {'': items};

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final entry in grouped.entries) ...[
            if (entry.key.isNotEmpty) ...[
              Text(
                entry.key,
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (var i = 0; i < entry.value.length; i++)
              AppFadeIn(
                delay: AppAnimations.staggerDelay(i, base: AppAnimations.instant),
                offset: const Offset(12, 0),
                child: _TimelineRow(
                  item: entry.value[i],
                  isLast: i == entry.value.length - 1,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  Map<String, List<ActivityStreamItem>> _groupByDay(List<ActivityStreamItem> items) {
    final fmt = DateFormat.yMMMd();
    final map = <String, List<ActivityStreamItem>>{};
    for (final item in items) {
      final key = fmt.format(item.timestamp.toLocal());
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});

  final ActivityStreamItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeFmt = DateFormat.jm();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.14),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(item.icon, size: 18, color: item.color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      Text(
                        timeFmt.format(item.timestamp.toLocal()),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
