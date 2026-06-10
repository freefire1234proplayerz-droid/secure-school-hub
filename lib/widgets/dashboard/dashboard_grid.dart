import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';

/// Responsive grid with staggered fade-in for dashboard widgets.
class DashboardGrid extends StatelessWidget {
  const DashboardGrid({
    super.key,
    required this.children,
    this.minItemWidth = 220,
    this.spacing = AppSpacing.sm,
    this.animate = true,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            AppBreakpoints.gridColumns(constraints.maxWidth, minItemWidth: minItemWidth);
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width: itemWidth,
                child: animate
                    ? AppFadeIn(
                        delay: AppAnimations.staggerDelay(i),
                        child: children[i],
                      )
                    : children[i],
              ),
          ],
        );
      },
    );
  }
}
