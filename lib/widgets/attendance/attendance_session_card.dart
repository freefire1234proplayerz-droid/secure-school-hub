import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'attendance_models.dart';

/// Session timing and status card for class management.
class AttendanceSessionCard extends StatefulWidget {
  const AttendanceSessionCard({
    super.key,
    required this.session,
    this.onStart,
    this.onEnd,
    this.isSelected = false,
    this.onTap,
  });

  final AttendanceSessionInfo session;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  State<AttendanceSessionCard> createState() => _AttendanceSessionCardState();
}

class _AttendanceSessionCardState extends State<AttendanceSessionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = widget.session.isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1,
        duration: AppAnimations.fast,
        child: GlassCard(
          onTap: widget.onTap,
          variant: widget.isSelected || active
              ? GlassCardVariant.elevated
              : GlassCardVariant.standard,
          tintColor: active
              ? scheme.primary.withValues(alpha: 0.08)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: active
                          ? AppGradients.heroAccent(scheme)
                          : null,
                      color: active ? null : scheme.surfaceContainerHighest,
                      borderRadius: AppSpacing.borderRadiusXs,
                    ),
                    child: Text(
                      active ? 'LIVE' : 'Scheduled',
                      style: textTheme.labelSmall?.copyWith(
                        color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.session.startTime} – ${widget.session.endTime}',
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.session.label,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (widget.session.subject != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.session.subject!,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (widget.onStart != null || widget.onEnd != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (widget.onStart != null && !active)
                      TextButton.icon(
                        onPressed: widget.onStart,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Start'),
                      ),
                    if (widget.onEnd != null && active)
                      TextButton.icon(
                        onPressed: widget.onEnd,
                        icon: const Icon(Icons.stop_rounded, size: 18),
                        label: const Text('End session'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Class / subject / date selector bar.
class ClassManagementBar extends StatelessWidget {
  const ClassManagementBar({
    super.key,
    required this.classes,
    required this.selectedClass,
    required this.onClassChanged,
    this.subjects = const [],
    this.selectedSubject,
    this.onSubjectChanged,
    this.selectedDate,
    this.onDateChanged,
    this.sessionStatus,
  });

  final List<String> classes;
  final String selectedClass;
  final ValueChanged<String> onClassChanged;
  final List<String> subjects;
  final String? selectedSubject;
  final ValueChanged<String>? onSubjectChanged;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateChanged;
  final String? sessionStatus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final date = selectedDate ?? DateTime.now();

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _DropdownField<String>(
            label: 'Class',
            value: selectedClass,
            items: classes,
            onChanged: (v) => onClassChanged(v!),
            icon: Icons.class_outlined,
          ),
          if (subjects.isNotEmpty && onSubjectChanged != null)
            _DropdownField<String>(
              label: 'Subject',
              value: selectedSubject ?? subjects.first,
              items: subjects,
              onChanged: (v) => onSubjectChanged!(v!),
              icon: Icons.menu_book_outlined,
            ),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(date.year - 1),
                lastDate: DateTime(date.year + 1),
              );
              if (picked != null) onDateChanged?.call(picked);
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(
              '${date.day}/${date.month}/${date.year}',
              style: textTheme.labelLarge,
            ),
          ),
          if (sessionStatus != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    sessionStatus!,
                    style: textTheme.labelMedium?.copyWith(
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

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            isDense: true,
            items: [
              for (final item in items)
                DropdownMenuItem(value: item, child: Text('$item')),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
