import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../utils/json_num.dart';
import '../dashboard/dashboard_grid.dart';
import '../dashboard/dashboard_section.dart';
import '../design_system/app_button.dart';
import '../design_system/glass_card.dart';
import 'attendance_chart_card.dart';
import 'attendance_models.dart';
import 'attendance_ring_chart.dart';
import 'attendance_stat_card.dart';
import 'attendance_timeline.dart';

/// Parent-facing attendance experience module.
class ParentAttendanceModule extends StatelessWidget {
  const ParentAttendanceModule({
    super.key,
    required this.childName,
    required this.attendancePercent,
    required this.notifications,
    this.onRefresh,
    this.onRequestLeave,
  });

  final String childName;
  final int attendancePercent;
  final List<AttendanceActivityItem> notifications;
  final VoidCallback? onRefresh;
  final VoidCallback? onRequestLeave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChildProgressCard(
          childName: childName,
          attendancePercent: attendancePercent,
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardGrid(
          children: [
            AttendanceStatCard(
              label: 'This month',
              value: '$attendancePercent%',
              icon: Icons.calendar_month_outlined,
              color: scheme.primary,
              subtitle: 'On track for term goals',
            ),
            AttendanceStatCard(
              label: 'Days present',
              value: '${(attendancePercent * 0.22).round()}',
              icon: Icons.check_circle_outline,
              color: Colors.teal,
              subtitle: 'Approx. school days',
            ),
            AttendanceStatCard(
              label: 'Absences',
              value: '${(100 - attendancePercent) ~/ 8}',
              icon: Icons.event_busy_outlined,
              color: Colors.deepOrange,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= AppBreakpoints.tablet) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: AttendanceChartCard(
                      values: [
                        attendancePercent - 4,
                        attendancePercent - 1,
                        attendancePercent + 2,
                        attendancePercent.toDouble(),
                        attendancePercent - 2,
                        attendancePercent + 1,
                      ],
                      title: 'Monthly attendance graph',
                      subtitle: 'Last 6 weeks',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AttendanceRingChart(
                      percent: attendancePercent / 100,
                      label: 'Overall',
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
                  values: [
                    attendancePercent - 4,
                    attendancePercent - 1,
                    attendancePercent + 2,
                    attendancePercent.toDouble(),
                    attendancePercent - 2,
                    attendancePercent + 1,
                  ],
                  title: 'Monthly attendance graph',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Absence notifications',
          useGlassPanel: false,
          animate: false,
          action: onRefresh != null
              ? AppButton(
                  label: 'Refresh',
                  icon: Icons.refresh,
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                  onPressed: onRefresh,
                )
              : null,
          child: AttendanceTimeline(
            items: notifications,
            title: 'School updates',
            emptyMessage: 'No absence alerts — great attendance!',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Attendance history',
          useGlassPanel: false,
          animate: false,
          child: _HistoryTimeline(percent: attendancePercent),
        ),
        const SizedBox(height: AppSpacing.lg),
        DashboardSection(
          title: 'Leave request',
          useGlassPanel: false,
          animate: false,
          child: _LeaveRequestForm(onSubmit: onRequestLeave),
        ),
      ],
    );
  }
}

class _ChildProgressCard extends StatelessWidget {
  const _ChildProgressCard({
    required this.childName,
    required this.attendancePercent,
  });

  final String childName;
  final int attendancePercent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      variant: GlassCardVariant.elevated,
      tintColor: scheme.primary.withValues(alpha: 0.06),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              childName.isNotEmpty ? childName[0] : '?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  childName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  'Attendance progress',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: attendancePercent / 100,
                    minHeight: 10,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$attendancePercent% overall • Present today',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.teal,
                        fontWeight: FontWeight.w700,
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

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final items = List.generate(5, (i) {
      final date = DateTime.now().subtract(Duration(days: i));
      return AttendanceActivityItem(
        title: i == 0 ? 'Present — on time' : 'Present',
        subtitle: 'Class 8A • Morning session',
        timestamp: date,
        status: i == 2 ? AttendanceStatus.late : AttendanceStatus.present,
      );
    });

    return AttendanceTimeline(
      items: items,
      title: 'Recent history',
    );
  }
}

class _LeaveRequestForm extends StatefulWidget {
  const _LeaveRequestForm({this.onSubmit});

  final VoidCallback? onSubmit;

  @override
  State<_LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends State<_LeaveRequestForm> {
  final _reasonController = TextEditingController();
  DateTime? _from;
  DateTime? _to;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Submit a leave request to your child\'s teacher.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => _from = picked);
                },
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  _from == null
                      ? 'From date'
                      : '${_from!.day}/${_from!.month}/${_from!.year}',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _from ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setState(() => _to = picked);
                },
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  _to == null
                      ? 'To date'
                      : '${_to!.day}/${_to!.month}/${_to!.year}',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Family event, medical appointment…',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Submit leave request',
          icon: Icons.send_outlined,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Leave request submitted — teacher will be notified.',
                ),
              ),
            );
            widget.onSubmit?.call();
          },
          expand: true,
        ),
      ],
    );
  }
}

/// Helper to build parent activity items from dashboard notifications.
List<AttendanceActivityItem> parentActivityFromNotifications(
  List<Map<String, dynamic>> rows,
) {
  return rows.map((row) {
    final type = row['type']?.toString();
    final created = DateTime.tryParse(row['created_at']?.toString() ?? '') ??
        DateTime.now();
    return AttendanceActivityItem(
      title: row['title']?.toString() ?? 'School update',
      subtitle: row['body']?.toString() ?? '',
      timestamp: created,
      status: type == 'attendance'
          ? AttendanceStatus.present
          : AttendanceStatus.unmarked,
      icon: type == 'attendance'
          ? Icons.verified_user_outlined
          : Icons.notifications_none,
    );
  }).toList();
}

int parentAttendancePercent(Map<String, dynamic> dashboard) =>
    asInt(dashboard['attendancePercent'], 94);
