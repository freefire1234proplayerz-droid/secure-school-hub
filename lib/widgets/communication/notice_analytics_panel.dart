import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../dashboard/dashboard_grid.dart';
import '../design_system/glass_card.dart';
import 'announcement_stats_card.dart';

/// Admin notice analytics: delivery, read receipts, engagement charts.
class NoticeAnalyticsPanel extends StatelessWidget {
  const NoticeAnalyticsPanel({
    super.key,
    required this.totalSent,
    required this.totalRead,
    required this.openRate,
    this.weeklyEngagement = const [62, 71, 68, 84, 79, 88],
    this.scheduledCount = 3,
  });

  final int totalSent;
  final int totalRead;
  final double openRate;
  final List<double> weeklyEngagement;
  final int scheduledCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final readRate = totalSent == 0 ? 0.0 : totalRead / totalSent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardGrid(
          minItemWidth: 180,
          children: [
            AnnouncementStatsCard(
              label: 'Notices sent',
              value: '$totalSent',
              icon: Icons.send_rounded,
              color: scheme.primary,
              trend: '+12%',
            ),
            AnnouncementStatsCard(
              label: 'Read receipts',
              value: '$totalRead',
              icon: Icons.mark_email_read_outlined,
              color: Colors.teal,
              subtitle: '${(readRate * 100).round()}% read rate',
            ),
            AnnouncementStatsCard(
              label: 'Open rate',
              value: '${openRate.round()}%',
              icon: Icons.insights_outlined,
              color: Colors.indigo,
            ),
            AnnouncementStatsCard(
              label: 'Scheduled',
              value: '$scheduledCount',
              icon: Icons.schedule_send_outlined,
              color: Colors.deepOrange,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= AppBreakpoints.tablet;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _EngagementChart(values: weeklyEngagement),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _ReadReceiptsPanel(readRate: readRate)),
                ],
              );
            }
            return Column(
              children: [
                _EngagementChart(values: weeklyEngagement),
                const SizedBox(height: AppSpacing.sm),
                _ReadReceiptsPanel(readRate: readRate),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _ScheduledCalendar(),
      ],
    );
  }
}

class _EngagementChart extends StatelessWidget {
  const _EngagementChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audience engagement',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < values.length; i++)
                        FlSpot(i.toDouble(), values[i]),
                    ],
                    isCurved: true,
                    barWidth: 3,
                    color: scheme.primary,
                    belowBarData: BarAreaData(
                      show: true,
                      color: scheme.primary.withValues(alpha: 0.1),
                    ),
                    dotData: const FlDotData(show: true),
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

class _ReadReceiptsPanel extends StatelessWidget {
  const _ReadReceiptsPanel({required this.readRate});

  final double readRate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Read receipts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: readRate.clamp(0, 1),
              minHeight: 12,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${(readRate * 100).round()}% of recipients opened notices',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final row in [
            ('Parents', 0.86),
            ('Teachers', 0.92),
            ('Admins', 0.98),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1)),
                  Text('${(row.$2 * 100).round()}%'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ScheduledCalendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduled announcement calendar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < 3; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${now.add(Duration(days: i + 1)).day}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              title: Text(
                [
                  'PTA meeting reminder',
                  'Fee deadline notice',
                  'Sports day announcement',
                ][i],
              ),
              subtitle: Text(
                'Scheduled • ${['Parents', 'All school', 'Class 8A'][i]}',
              ),
              trailing: const Icon(Icons.schedule_send_outlined),
            ),
        ],
      ),
    );
  }
}
