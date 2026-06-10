import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'communication_models.dart';

/// Role / class audience targeting for notice compose.
class AudienceSelector extends StatelessWidget {
  const AudienceSelector({
    super.key,
    required this.selectedAudience,
    required this.onAudienceChanged,
    this.selectedClasses = const [],
    this.onClassesChanged,
    this.availableClasses = const ['Class 8A', 'Class 8B', 'Class 9A'],
    this.showRoleTargeting = true,
  });

  final NoticeAudience selectedAudience;
  final ValueChanged<NoticeAudience> onAudienceChanged;
  final List<String> selectedClasses;
  final ValueChanged<List<String>>? onClassesChanged;
  final List<String> availableClasses;
  final bool showRoleTargeting;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audience',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (showRoleTargeting) ...[
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final audience in NoticeAudience.values)
                  FilterChip(
                    label: Text(_audienceLabel(audience)),
                    selected: selectedAudience == audience,
                    onSelected: (_) => onAudienceChanged(audience),
                    avatar: Icon(_audienceIcon(audience), size: 16),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            'Class targeting',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final className in availableClasses)
                FilterChip(
                  label: Text(className),
                  selected: selectedClasses.contains(className),
                  onSelected: (selected) {
                    if (onClassesChanged == null) return;
                    final next = [...selectedClasses];
                    if (selected) {
                      next.add(className);
                    } else {
                      next.remove(className);
                    }
                    onClassesChanged!(next);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _audienceLabel(NoticeAudience a) => switch (a) {
        NoticeAudience.all => 'Everyone',
        NoticeAudience.parents => 'Parents',
        NoticeAudience.teachers => 'Teachers',
        NoticeAudience.admins => 'Admins',
        NoticeAudience.classTarget => 'Class',
      };

  IconData _audienceIcon(NoticeAudience a) => switch (a) {
        NoticeAudience.all => Icons.public,
        NoticeAudience.parents => Icons.family_restroom,
        NoticeAudience.teachers => Icons.school_outlined,
        NoticeAudience.admins => Icons.admin_panel_settings_outlined,
        NoticeAudience.classTarget => Icons.class_outlined,
      };
}

/// Small audience badge for notice cards.
class AudienceBadge extends StatelessWidget {
  const AudienceBadge({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.65),
        borderRadius: AppSpacing.borderRadiusXs,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: scheme.onSecondaryContainer),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSecondaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}
