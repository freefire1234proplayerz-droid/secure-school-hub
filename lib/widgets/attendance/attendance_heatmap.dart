import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'attendance_models.dart';

/// Student attendance heatmap grid (days × students or weeks).
class AttendanceHeatmap extends StatelessWidget {
  const AttendanceHeatmap({
    super.key,
    required this.rows,
    this.columnLabels = const ['M', 'T', 'W', 'T', 'F', 'S'],
    this.title = 'Attendance heatmap',
  });

  /// Each inner list is a row of status values for column labels.
  final List<List<AttendanceStatus>> rows;
  final List<String> columnLabels;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const SizedBox(width: 72),
              for (final label in columnLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var r = 0; r < rows.length; r++)
            AppFadeIn(
              delay: AppAnimations.staggerDelay(r, base: AppAnimations.instant),
              offset: const Offset(-6, 0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        'S${r + 1}',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    for (var c = 0; c < rows[r].length; c++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: _HeatCell(status: rows[r][c]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            children: [
              for (final status in [
                AttendanceStatus.present,
                AttendanceStatus.late,
                AttendanceStatus.absent,
                AttendanceStatus.unmarked,
              ])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeatCell(status: status, size: 12),
                    const SizedBox(width: 4),
                    Text(status.label, style: textTheme.labelSmall),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({required this.status, this.size = 20});

  final AttendanceStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      AttendanceStatus.present => Colors.teal,
      AttendanceStatus.late => Colors.deepOrange,
      AttendanceStatus.absent => scheme.error,
      AttendanceStatus.unmarked => scheme.surfaceContainerHighest,
    };

    return AnimatedContainer(
      duration: AppAnimations.fast,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: status == AttendanceStatus.unmarked ? 1 : 0.85),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
