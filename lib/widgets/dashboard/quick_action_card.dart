import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';

/// Tappable glass action tile for dashboard quick actions.
class QuickActionCard extends StatefulWidget {
  const QuickActionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.description,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? description;
  final Color? color;

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.color ?? scheme.primary;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.015 : 1.0,
        duration: AppAnimations.fast,
        child: GlassCard(
          onTap: widget.onTap,
          variant: _hovered ? GlassCardVariant.elevated : GlassCardVariant.standard,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppAnimations.fast,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: _hovered ? 0.18 : 0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(widget.icon, color: accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _hovered ? 0 : -0.02,
                duration: AppAnimations.fast,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
