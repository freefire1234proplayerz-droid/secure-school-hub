import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import 'shell_models.dart';

/// Persistent desktop sidebar with collapse animation and active indicators.
class SidebarNavigation extends StatelessWidget {
  const SidebarNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.collapsed,
    required this.onToggleCollapse,
    this.brandTitle = 'Secure School Hub',
    this.brandSubtitle = 'Enterprise',
  });

  final List<ShellNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final String brandTitle;
  final String brandSubtitle;

  static const double expandedWidth = 260;
  static const double collapsedWidth = 76;
  static const double minExpandedWidth = 220;
  static const double maxExpandedWidth = 280;

  static double safeWidth({
    required bool collapsed,
    required double availableWidth,
  }) {
    final safeAvailable = _safeDimension(availableWidth);
    final targetWidth = collapsed
        ? collapsedWidth
        : _safeClamp(
            expandedWidth,
            min: minExpandedWidth,
            max: maxExpandedWidth,
          );
    final upperBound = safeAvailable > 0 ? safeAvailable : targetWidth;
    final lowerBound =
        upperBound < collapsedWidth ? upperBound : collapsedWidth;
    return _safeClamp(targetWidth, min: lowerBound, max: upperBound);
  }

  static double _safeDimension(double value) {
    if (!value.isFinite || value.isNaN || value <= 0) return 0;
    return value;
  }

  static double _safeClamp(
    double value, {
    required double min,
    required double max,
  }) {
    final safeMin = min.isFinite && !min.isNaN ? min : 0.0;
    final safeMax = max.isFinite && !max.isNaN ? max : safeMin;
    final lower = safeMin <= safeMax ? safeMin : safeMax;
    final upper = safeMax >= lower ? safeMax : lower;
    final raw = value.isFinite && !value.isNaN ? value : lower;
    return raw.clamp(lower, upper).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return LayoutBuilder(
      builder: (context, constraints) {
        final safeAvailable = constraints.hasBoundedWidth
            ? _safeDimension(constraints.maxWidth)
            : _safeDimension(MediaQuery.sizeOf(context).width);
        final width = safeWidth(
          collapsed: collapsed,
          availableWidth: safeAvailable,
        );

        return SizedBox(
          width: width,
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(width: width),
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.surface.withValues(alpha: 0.92),
                      scheme.surfaceContainerLow.withValues(alpha: 0.88),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    _BrandHeader(
                      collapsed: collapsed,
                      title: brandTitle,
                      subtitle: brandSubtitle,
                      onToggle: onToggleCollapse,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _NavTile(
                            item: items[index],
                            selected: index == selectedIndex,
                            collapsed: collapsed,
                            onTap: () => onSelected(index),
                          );
                        },
                      ),
                    ),
                    if (!collapsed)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            borderRadius: AppSpacing.borderRadiusMd,
                            gradient: AppGradients.glassSheen(brightness),
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                size: 18,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  'End-to-end encrypted',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.collapsed,
    required this.title,
    required this.subtitle,
    required this.onToggle,
  });

  final bool collapsed;
  final String title;
  final String subtitle;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BrandMark(scheme: scheme),
            const SizedBox(height: AppSpacing.xxs),
            IconButton(
              tooltip: 'Expand sidebar',
              onPressed: onToggle,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              icon: const AnimatedRotation(
                turns: 0.5,
                duration: AppAnimations.normal,
                child: Icon(Icons.menu_open_rounded, size: 22),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          _BrandMark(scheme: scheme),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Collapse sidebar',
            onPressed: onToggle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            icon: const AnimatedRotation(
              turns: 0,
              duration: AppAnimations.normal,
              child: Icon(Icons.menu_open_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: AppGradients.heroAccent(scheme),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final ShellNavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted || _hovered == value) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = widget.selected;
    final bgColor = active
        ? scheme.primary.withValues(alpha: 0.14)
        : _hovered
            ? scheme.onSurface.withValues(alpha: 0.06)
            : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: Tooltip(
          message: widget.collapsed ? widget.item.label : '',
          preferBelow: false,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: AppSpacing.borderRadiusMd,
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.collapsed ? AppSpacing.sm : AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: AppSpacing.borderRadiusMd,
                  border: active
                      ? Border.all(
                          color: scheme.primary.withValues(alpha: 0.35),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? widget.item.activeIcon : widget.item.icon,
                      size: 22,
                      color: active ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    if (!widget.collapsed) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          widget.item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? scheme.primary : scheme.onSurface,
                          ),
                        ),
                      ),
                      if (widget.item.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.error,
                            borderRadius: AppSpacing.borderRadiusXs,
                          ),
                          child: Text(
                            widget.item.badge!,
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.onError,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (widget.item.shortcut != null && !active)
                        Text(
                          '⌘${widget.item.shortcut}',
                          style: textTheme.labelSmall?.copyWith(
                            color:
                                scheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact navigation rail for tablet layouts.
class ShellNavigationRail extends StatelessWidget {
  const ShellNavigationRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ShellNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeIndex =
        items.isEmpty ? 0 : selectedIndex.clamp(0, items.length - 1);

    if (items.isEmpty) return const SizedBox.shrink();

    return NavigationRail(
      selectedIndex: safeIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.selected,
      backgroundColor: scheme.surface.withValues(alpha: 0.85),
      indicatorColor: scheme.primary.withValues(alpha: 0.14),
      leading: Padding(
        padding:
            const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.md),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppGradients.heroAccent(scheme),
            borderRadius: AppSpacing.borderRadiusSm,
          ),
          child:
              const Icon(Icons.school_rounded, color: Colors.white, size: 22),
        ),
      ),
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: Text(item.label),
          ),
      ],
    );
  }
}

/// Bottom navigation bar for mobile layouts.
class ShellBottomNavigation extends StatelessWidget {
  const ShellBottomNavigation({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<ShellNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final visible = items.length > 5 ? items.sublist(0, 5) : items;
    if (visible.isEmpty) return const SizedBox.shrink();

    final index = selectedIndex.clamp(0, visible.length - 1);

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onSelected,
      destinations: [
        for (final item in visible)
          NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.activeIcon),
            label: item.label,
          ),
      ],
    );
  }
}
