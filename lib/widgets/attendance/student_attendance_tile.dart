import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'attendance_models.dart';

/// Student row with inline attendance status toggles and optional swipe.
class StudentAttendanceTile extends StatefulWidget {
  const StudentAttendanceTile({
    super.key,
    required this.student,
    required this.onStatusChanged,
    this.enableSwipe = true,
    this.index = 0,
  });

  final StudentAttendanceRecord student;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  final bool enableSwipe;
  final int index;

  @override
  State<StudentAttendanceTile> createState() => _StudentAttendanceTileState();
}

class _StudentAttendanceTileState extends State<StudentAttendanceTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final student = widget.student;
    final isMobile = MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

    Widget tile = AppFadeIn(
      delay: AppAnimations.staggerDelay(widget.index, base: AppAnimations.instant),
      offset: const Offset(0, 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _hovered ? 1.005 : 1,
          duration: AppAnimations.fast,
          child: GlassCard(
            variant: _hovered ? GlassCardVariant.elevated : GlassCardVariant.flat,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: student.status
                      .color(scheme)
                      .withValues(alpha: 0.15),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                    style: textTheme.titleSmall?.copyWith(
                      color: student.status.color(scheme),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${student.className} • ${student.rollNo}',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) _StatusToggles(
                  status: student.status,
                  onChanged: widget.onStatusChanged,
                )
                else
                  _MobileStatusMenu(
                    status: student.status,
                    onChanged: widget.onStatusChanged,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.enableSwipe && isMobile) {
      tile = Dismissible(
        key: ValueKey('student-${student.id}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            widget.onStatusChanged(AttendanceStatus.present);
          } else {
            widget.onStatusChanged(AttendanceStatus.absent);
          }
          return false;
        },
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: AppSpacing.lg),
          color: Colors.teal.withValues(alpha: 0.2),
          child: const Icon(Icons.check_circle, color: Colors.teal),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          color: scheme.error.withValues(alpha: 0.2),
          child: Icon(Icons.cancel, color: scheme.error),
        ),
        child: tile,
      );
    }

    return tile;
  }
}

class _StatusToggles extends StatelessWidget {
  const _StatusToggles({required this.status, required this.onChanged});

  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AttendanceStatus>(
      segments: [
        for (final s in [
          AttendanceStatus.present,
          AttendanceStatus.late,
          AttendanceStatus.absent,
        ])
          ButtonSegment(
            value: s,
            icon: Icon(s.icon, size: 16),
            label: Text(s.label, style: const TextStyle(fontSize: 11)),
          ),
      ],
      selected: {status == AttendanceStatus.unmarked ? AttendanceStatus.present : status},
      onSelectionChanged: (set) => onChanged(set.first),
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _MobileStatusMenu extends StatelessWidget {
  const _MobileStatusMenu({required this.status, required this.onChanged});

  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<AttendanceStatus>(
      initialValue: status,
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: status.color(scheme).withValues(alpha: 0.12),
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 16, color: status.color(scheme)),
            const SizedBox(width: 4),
            Text(status.label, style: const TextStyle(fontSize: 12)),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
      itemBuilder: (context) => [
        for (final s in AttendanceStatus.values)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Icon(s.icon, size: 18, color: s.color(scheme)),
                const SizedBox(width: 8),
                Text(s.label),
              ],
            ),
          ),
      ],
    );
  }
}

/// Desktop table layout for manual attendance.
class StudentAttendanceTable extends StatelessWidget {
  const StudentAttendanceTable({
    super.key,
    required this.students,
    required this.onStatusChanged,
  });

  final List<StudentAttendanceRecord> students;
  final void Function(int index, AttendanceStatus status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusMd,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          columns: const [
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Roll')),
            DataColumn(label: Text('Class')),
            DataColumn(label: Text('Status')),
          ],
          rows: [
            for (var i = 0; i < students.length; i++)
              DataRow(
                cells: [
                  DataCell(Text(
                    students[i].name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                  DataCell(Text(students[i].rollNo)),
                  DataCell(Text(students[i].className)),
                  DataCell(
                    SegmentedButton<AttendanceStatus>(
                      segments: [
                        for (final s in [
                          AttendanceStatus.present,
                          AttendanceStatus.late,
                          AttendanceStatus.absent,
                        ])
                          ButtonSegment(
                            value: s,
                            icon: Icon(s.icon, size: 14),
                          ),
                      ],
                      selected: {
                        students[i].status == AttendanceStatus.unmarked
                            ? AttendanceStatus.present
                            : students[i].status,
                      },
                      onSelectionChanged: (set) =>
                          onStatusChanged(i, set.first),
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
