import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'attendance_models.dart';

/// Vertical timeline for recent attendance activity.
class AttendanceTimeline extends StatelessWidget {
  const AttendanceTimeline({
    super.key,
    required this.items,
    this.title = 'Recent activity',
    this.emptyMessage = 'No attendance marks yet today.',
  });

  final List<AttendanceActivityItem> items;
  final String title;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final timeFmt = DateFormat.jm();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              AppFadeIn(
                delay: AppAnimations.staggerDelay(i, base: AppAnimations.instant),
                offset: const Offset(8, 0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: items[i]
                                  .status
                                  .color(scheme)
                                  .withValues(alpha: 0.14),
                              borderRadius: AppSpacing.borderRadiusSm,
                            ),
                            child: Icon(
                              items[i].icon ?? items[i].status.icon,
                              size: 18,
                              color: items[i].status.color(scheme),
                            ),
                          ),
                          if (i != items.length - 1)
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
                          padding: EdgeInsets.only(
                            bottom: i == items.length - 1 ? 0 : AppSpacing.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      items[i].title,
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timeFmt.format(items[i].timestamp.toLocal()),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                items[i].subtitle,
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
                ),
              ),
            ],
        ],
      ),
    );
  }
}
