import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';

/// KPI tile for attendance statistics (present, absent, late, percent).
class AttendanceStatCard extends StatefulWidget {
  const AttendanceStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.isLoading = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final bool isLoading;

  @override
  State<AttendanceStatCard> createState() => _AttendanceStatCardState();
}

class _AttendanceStatCardState extends State<AttendanceStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1,
        duration: AppAnimations.fast,
        child: GlassCard(
          variant: _hovered ? GlassCardVariant.elevated : GlassCardVariant.standard,
          tintColor: widget.color.withValues(alpha: _hovered ? 0.08 : 0.04),
          child: widget.isLoading
              ? _Skeleton(color: widget.color)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.color.withValues(alpha: 0.25),
                                widget.color.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Icon(widget.icon, color: widget.color, size: 22),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
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
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        widget.subtitle!,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final shimmer = color.withValues(alpha: 0.12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: AppSpacing.borderRadiusSm,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: 64,
          height: 28,
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: AppSpacing.borderRadiusXs,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: 100,
          height: 14,
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: AppSpacing.borderRadiusXs,
          ),
        ),
      ],
    );
  }
}
