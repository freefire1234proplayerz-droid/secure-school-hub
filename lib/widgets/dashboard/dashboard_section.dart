import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';

/// Titled dashboard section with optional action and glass panel wrapper.
class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    this.action,
    required this.child,
    this.useGlassPanel = true,
    this.sectionKey,
    this.animate = true,
  });

  final String title;
  final Widget? action;
  final Widget child;
  final bool useGlassPanel;
  final Key? sectionKey;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget section = Padding(
      key: sectionKey,
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          useGlassPanel ? GlassCard(child: child) : child,
        ],
      ),
    );

    if (animate) {
      section = AppFadeIn(child: section);
    }

    return section;
  }
}

/// Page-level dashboard header block (title, subtitle, trailing CTA).
class DashboardPageHeader extends StatelessWidget {
  const DashboardPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        );

        if (compact || trailing == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              if (trailing != null) ...[
                const SizedBox(height: AppSpacing.sm),
                trailing!,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        );
      },
    );
  }
}
