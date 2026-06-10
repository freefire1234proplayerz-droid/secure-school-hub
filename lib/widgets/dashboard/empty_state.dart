import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';

/// Empty state placeholder for dashboard sections.
class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 48 : 64,
          height: compact ? 48 : 64,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: AppSpacing.borderRadiusLg,
          ),
          child: Icon(
            icon,
            size: compact ? 24 : 32,
            color: scheme.primary.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        if (action != null) ...[
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          action!,
        ],
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: content,
      );
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Center(child: content),
    );
  }
}
