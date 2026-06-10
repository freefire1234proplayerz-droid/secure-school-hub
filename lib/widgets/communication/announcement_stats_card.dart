import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';

/// Delivery / engagement stat tile for admin broadcast dashboard.
class AnnouncementStatsCard extends StatefulWidget {
  const AnnouncementStatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
    this.isLoading = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final String? trend;
  final bool isLoading;

  @override
  State<AnnouncementStatsCard> createState() => _AnnouncementStatsCardState();
}

class _AnnouncementStatsCardState extends State<AnnouncementStatsCard> {
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
              ? Container(
                  height: 88,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(widget.icon, color: widget.color, size: 22),
                        const Spacer(),
                        if (widget.trend != null)
                          Text(
                            widget.trend!,
                            style: textTheme.labelSmall?.copyWith(
                              color: widget.color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.value,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.label,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
