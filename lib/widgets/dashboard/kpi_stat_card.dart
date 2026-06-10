import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';

/// Glass KPI tile with icon, value, trend, and optional detail line.
class KPIStatCard extends StatefulWidget {
  const KPIStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.detail,
    this.trend,
    this.isLoading = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? detail;
  final String? trend;
  final bool isLoading;

  @override
  State<KPIStatCard> createState() => _KPIStatCardState();
}

class _KPIStatCardState extends State<KPIStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.standard,
        child: GlassCard(
          variant: _hovered ? GlassCardVariant.elevated : GlassCardVariant.standard,
          tintColor: widget.color.withValues(alpha: _hovered ? 0.06 : 0.03),
          child: widget.isLoading
              ? const _KPISkeleton()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.color.withValues(alpha: 0.22),
                                widget.color.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Icon(widget.icon, color: widget.color, size: 22),
                        ),
                        const Spacer(),
                        if (widget.trend != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.12),
                              borderRadius: AppSpacing.borderRadiusXs,
                            ),
                            child: Text(
                              widget.trend!,
                              style: textTheme.labelSmall?.copyWith(
                                color: widget.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.value,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      widget.label,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.detail != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.detail!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _KPISkeleton extends StatelessWidget {
  const _KPISkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shimmer = scheme.onSurface.withValues(alpha: 0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 80,
          height: 28,
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: AppSpacing.borderRadiusXs,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: 120,
          height: 16,
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: AppSpacing.borderRadiusXs,
          ),
        ),
      ],
    );
  }
}
