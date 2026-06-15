import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'attendance_models.dart';

/// Search and filter controls for manual attendance lists.
class AttendanceFilterBar extends StatelessWidget {
  const AttendanceFilterBar({
    super.key,
    required this.searchController,
    this.onSearchChanged,
    this.statusFilter,
    this.onStatusFilterChanged,
    this.onBulkPresent,
    this.onBulkAbsent,
    this.onBulkLate,
    this.showBulkActions = true,
  });

  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;
  final AttendanceStatus? statusFilter;
  final ValueChanged<AttendanceStatus?>? onStatusFilterChanged;
  final VoidCallback? onBulkPresent;
  final VoidCallback? onBulkAbsent;
  final VoidCallback? onBulkLate;
  final bool showBulkActions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search students…',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: const OutlineInputBorder(
                borderRadius: AppSpacing.borderRadiusMd,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusChips(
                  selected: statusFilter,
                  onChanged: onStatusFilterChanged,
                ),
                if (showBulkActions) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _BulkActions(
                    onPresent: onBulkPresent,
                    onAbsent: onBulkAbsent,
                    onLate: onBulkLate,
                  ),
                ],
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _StatusChips(
                    selected: statusFilter,
                    onChanged: onStatusFilterChanged,
                  ),
                ),
                if (showBulkActions) ...[
                  const SizedBox(width: AppSpacing.md),
                  _BulkActions(
                    onPresent: onBulkPresent,
                    onAbsent: onBulkAbsent,
                    onLate: onBulkLate,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({this.selected, this.onChanged});

  final AttendanceStatus? selected;
  final ValueChanged<AttendanceStatus?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        FilterChip(
          label: const Text('All'),
          selected: selected == null,
          onSelected: (_) => onChanged?.call(null),
        ),
        for (final status in [
          AttendanceStatus.present,
          AttendanceStatus.absent,
          AttendanceStatus.late,
          AttendanceStatus.unmarked,
        ])
          FilterChip(
            label: Text(status.label),
            selected: selected == status,
            onSelected: (_) => onChanged?.call(status),
            avatar: Icon(status.icon, size: 16),
          ),
      ],
    );
  }
}

class _BulkActions extends StatelessWidget {
  const _BulkActions({
    this.onPresent,
    this.onAbsent,
    this.onLate,
  });

  final VoidCallback? onPresent;
  final VoidCallback? onAbsent;
  final VoidCallback? onLate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        ActionChip(
          avatar: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('All present'),
          onPressed: onPresent,
        ),
        ActionChip(
          avatar: const Icon(Icons.cancel_outlined, size: 16),
          label: const Text('All absent'),
          onPressed: onAbsent,
        ),
        ActionChip(
          avatar: const Icon(Icons.schedule, size: 16),
          label: const Text('All late'),
          onPressed: onLate,
        ),
      ],
    );
  }
}
