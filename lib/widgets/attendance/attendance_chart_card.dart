import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';

/// Weekly / daily attendance trend chart card.
class AttendanceChartCard extends StatefulWidget {
  const AttendanceChartCard({
    super.key,
    required this.values,
    this.labels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    this.title = 'Weekly trend',
    this.subtitle,
    this.minY = 70,
    this.maxY = 100,
  });

  final List<double> values;
  final List<String> labels;
  final String title;
  final String? subtitle;
  final double minY;
  final double maxY;

  @override
  State<AttendanceChartCard> createState() => _AttendanceChartCardState();
}

class _AttendanceChartCardState extends State<AttendanceChartCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slower,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(_controller.value);
              return SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    minY: widget.minY,
                    maxY: widget.maxY,
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: 10,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}%',
                            style: textTheme.labelSmall,
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= widget.labels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                widget.labels[index],
                                style: textTheme.labelSmall,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots
                            .map(
                              (spot) => LineTooltipItem(
                                '${(spot.y * t).toStringAsFixed(0)}%',
                                TextStyle(
                                  color: scheme.onInverseSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < widget.values.length; i++)
                            FlSpot(i.toDouble(), widget.values[i] * t),
                        ],
                        isCurved: true,
                        barWidth: 3,
                        color: scheme.primary,
                        belowBarData: BarAreaData(
                          show: true,
                          color: scheme.primary.withValues(alpha: 0.1),
                        ),
                        dotData: FlDotData(
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                            radius: 4,
                            color: scheme.primary,
                            strokeWidth: 2,
                            strokeColor: scheme.surface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Monthly bar chart for parent / analytics views.
class AttendanceMonthlyChart extends StatelessWidget {
  const AttendanceMonthlyChart({
    super.key,
    required this.values,
    this.labels = const ['W1', 'W2', 'W3', 'W4'],
    this.title = 'Monthly analytics',
  });

  final List<double> values;
  final List<String> labels;
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
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: 100,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(labels[i], style: textTheme.labelSmall);
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              scheme.primary.withValues(alpha: 0.7),
                              scheme.primary,
                            ],
                          ),
                        ),
                      ],
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
