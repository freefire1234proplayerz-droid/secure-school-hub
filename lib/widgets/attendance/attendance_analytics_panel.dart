import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../dashboard/dashboard_grid.dart';
import '../design_system/glass_card.dart';
import 'attendance_chart_card.dart';
import 'attendance_models.dart';
import 'attendance_ring_chart.dart';
import 'attendance_stat_card.dart';

/// Analytics section with trends, alerts, and rankings.
class AttendanceAnalyticsPanel extends StatelessWidget {
  const AttendanceAnalyticsPanel({
    super.key,
    required this.attendancePercent,
    required this.weeklyTrend,
    this.lowAttendanceStudents = const [],
    this.monthlyValues = const [92, 94, 91, 95],
  });

  final double attendancePercent;
  final List<double> weeklyTrend;
  final List<({String name, double percent})> lowAttendanceStudents;
  final List<double> monthlyValues;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= AppBreakpoints.tablet;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AttendanceChartCard(
                      values: weeklyTrend,
                      title: 'Daily trends',
                      subtitle: 'Last 6 school days',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 200,
                    child: AttendanceRingChart(
                      percent: attendancePercent / 100,
                      label: 'Today',
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                AttendanceRingChart(percent: attendancePercent / 100),
                const SizedBox(height: AppSpacing.sm),
                AttendanceChartCard(
                  values: weeklyTrend,
                  title: 'Daily trends',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        AttendanceMonthlyChart(
          values: monthlyValues,
          title: 'Monthly analytics',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (lowAttendanceStudents.isNotEmpty) ...[
          Text(
            'Low attendance alerts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          DashboardGrid(
            minItemWidth: 200,
            children: [
              for (final student in lowAttendanceStudents)
                GlassCard(
                  tintColor: scheme.error.withValues(alpha: 0.06),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: scheme.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${student.percent.round()}% this month',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          'Student ranking',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _RankingList(students: lowAttendanceStudents),
        const SizedBox(height: AppSpacing.lg),
        _AbsencePatternCard(),
      ],
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.students});

  final List<({String name, double percent})> students;

  @override
  Widget build(BuildContext context) {
    final sorted = [...students]..sort((a, b) => b.percent.compareTo(a.percent));
    if (sorted.isEmpty) {
      return GlassCard(
        child: Text(
          'Rankings appear when enough attendance data is collected.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++)
            ListTile(
              leading: CircleAvatar(
                child: Text('${i + 1}'),
              ),
              title: Text(sorted[i].name),
              trailing: Text(
                '${sorted[i].percent.round()}%',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AbsencePatternCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final patterns = [
      ('Monday', 0.18),
      ('Friday', 0.14),
      ('After holidays', 0.22),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Absence patterns',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final (label, rate) in patterns)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(label)),
                      Text('${(rate * 100).round()}%'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        scheme.error.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Class-wise attendance summary cards.
class ClassAttendanceCards extends StatelessWidget {
  const ClassAttendanceCards({super.key, required this.classes});

  final List<ClassAttendanceSummary> classes;

  @override
  Widget build(BuildContext context) {
    return DashboardGrid(
      minItemWidth: 200,
      children: [
        for (final c in classes)
          AttendanceStatCard(
            label: c.className,
            value: '${(c.percent * 100).round()}%',
            icon: Icons.class_outlined,
            color: c.percent >= 0.9
                ? Colors.teal
                : c.percent >= 0.75
                    ? Colors.deepOrange
                    : Theme.of(context).colorScheme.error,
            subtitle: '${c.present}/${c.total} present • ${c.late} late',
          ),
      ],
    );
  }
}
