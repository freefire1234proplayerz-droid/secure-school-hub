import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../../services/frontend_stability_service.dart';
import '../design_system/gradient_background.dart';
import '../experience/production_experience.dart';
import 'dashboard_header.dart';
import 'shell_models.dart';
import 'sidebar_navigation.dart';

export 'dashboard_header.dart';
export 'notification_panel.dart';
export 'profile_menu.dart';
export 'shell_models.dart';
export 'sidebar_navigation.dart';

/// Adaptive application shell with sidebar, rail, bottom nav, and sticky header.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.navItems,
    required this.selectedIndex,
    required this.onNavSelected,
    required this.body,
    this.notifications = const [],
    this.quickActions = const [],
    this.onLogout,
    this.onRefresh,
    this.onSearch,
    this.searchHint = 'Search dashboard…',
    this.sectionKeys,
    this.isLoading = false,
    this.scrollController,
  });

  final String title;
  final List<ShellNavItem> navItems;
  final int selectedIndex;
  final ValueChanged<int> onNavSelected;
  final Widget body;
  final List<ShellNotification> notifications;
  final List<ShellQuickAction> quickActions;
  final VoidCallback? onLogout;
  final VoidCallback? onRefresh;
  final ValueChanged<String>? onSearch;
  final String searchHint;
  final Map<String, GlobalKey>? sectionKeys;
  final bool isLoading;
  final ScrollController? scrollController;

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  final _headerKey = GlobalKey<DashboardHeaderState>();
  final _experienceKey = GlobalKey<ProductionExperienceLayerState>();
  bool _sidebarCollapsed = false;
  bool _quickActionsOpen = false;
  bool _mobileNavOpen = false;
  bool _logoutDialogOpen = false;
  late ScrollController _scrollController;
  final _stability = FrontendStabilityService.instance;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController == widget.scrollController) return;
    if (oldWidget.scrollController == null) {
      _scrollController.dispose();
    }
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    _headerKey.currentState?.closeOverlays();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _handleNavSelected(int index) {
    _resetInteractions();
    widget.onNavSelected(index);
    _scrollToSection(index);
  }

  void _scrollToSection(int index) {
    if (widget.sectionKeys == null || index >= widget.navItems.length) return;
    final id = widget.navItems[index].id;
    final key = widget.sectionKeys![id];
    final context = key?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: AppAnimations.normal,
        curve: AppAnimations.standard,
        alignment: 0.05,
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isMeta = HardwareKeyboard.instance.isMetaPressed;
    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final modifier = isMeta || isCtrl;

    if (modifier && event.logicalKey == LogicalKeyboardKey.keyK) {
      _experienceKey.currentState?.openCommandPalette();
      return KeyEventResult.handled;
    }

    if (modifier && event.logicalKey == LogicalKeyboardKey.keyB) {
      final width = MediaQuery.sizeOf(context).width;
      if (AppBreakpoints.isDesktop(width)) {
        _toggleSidebar();
      }
      return KeyEventResult.handled;
    }

    if (modifier) {
      const digitKeys = [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit6,
        LogicalKeyboardKey.digit7,
        LogicalKeyboardKey.digit8,
        LogicalKeyboardKey.digit9,
      ];
      for (var i = 0; i < widget.navItems.length && i < digitKeys.length; i++) {
        final shortcut = widget.navItems[i].shortcut;
        if (shortcut == null) continue;
        final digitIndex = int.tryParse(shortcut);
        if (digitIndex != null &&
            digitIndex >= 1 &&
            digitIndex <= 9 &&
            event.logicalKey == digitKeys[digitIndex - 1]) {
          _handleNavSelected(i);
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }

  void _toggleSidebar() {
    _resetInteractions();
    if (!mounted) return;
    setState(() => _sidebarCollapsed = !_sidebarCollapsed);
  }

  Future<void> _openQuickActions() async {
    if (widget.quickActions.isEmpty || _quickActionsOpen) return;

    _resetInteractions();
    _quickActionsOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final viewportWidth = _safeWidth(
                constraints.hasBoundedWidth ? constraints.maxWidth : null,
                fallback: MediaQuery.sizeOf(context).width,
              );
              final panelWidth = _ShellLayoutMetrics.safeClamp(
                viewportWidth,
                min: 0,
                max: 560,
              );

              return SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 0,
                      maxWidth: panelWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Quick actions',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          for (final action in widget.quickActions)
                            ListTile(
                              leading: Icon(action.icon),
                              title: Text(action.label),
                              subtitle: action.description != null
                                  ? Text(action.description!)
                                  : null,
                              onTap: () {
                                Navigator.pop(context);
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) action.onTap();
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      if (mounted) {
        _quickActionsOpen = false;
        _resetInteractions();
      }
    }
  }

  void _resetInteractions() {
    _headerKey.currentState?.closeOverlays();
    _experienceKey.currentState?.closeOverlays();
    _stability.resetInteractions();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _confirmLogout() async {
    if (widget.onLogout == null || _logoutDialogOpen) return;
    _resetInteractions();
    _logoutDialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.logout_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Sign out?'),
        content: const Text(
          'This will close active panels and return Secure School Hub to the login screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );

    _logoutDialogOpen = false;
    if (!mounted || confirmed != true) return;
    _resetInteractions();
    widget.onLogout!();
  }

  double _safeWidth(double? value, {required double fallback}) {
    return _ShellLayoutMetrics.safeDimension(value, fallback: fallback);
  }

  Widget _buildShellBody({
    required bool isMobile,
    required bool isDesktop,
  }) {
    return Column(
      children: [
        DashboardHeader(
          key: _headerKey,
          title: widget.title,
          showMenuButton: isMobile,
          onMenuToggle: isMobile
              ? () => _showMobileNav(context)
              : isDesktop
                  ? _toggleSidebar
                  : null,
          notifications: widget.notifications,
          onLogout: widget.onLogout == null ? null : _confirmLogout,
          onRefresh: widget.onRefresh,
          onSearch: widget.onSearch,
          searchHint: widget.searchHint,
        ),
        Expanded(
          child: widget.isLoading
              ? const _DashboardLoadingSkeleton()
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: ResponsiveContainer(
                    child: widget.body,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAdaptiveBody(double viewportWidth) {
    final metrics = _ShellLayoutMetrics.fromViewport(
      viewportWidth,
      sidebarCollapsed: _sidebarCollapsed,
    );
    final isMobile = metrics.breakpoint == AppBreakpoint.mobile;
    final isTablet = metrics.breakpoint == AppBreakpoint.tablet;
    final isDesktop = metrics.breakpoint == AppBreakpoint.desktop ||
        metrics.breakpoint == AppBreakpoint.wide;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop)
          AnimatedContainer(
            duration: AppAnimations.normal,
            curve: AppAnimations.standard,
            width: metrics.sidebarWidth,
            constraints: BoxConstraints.tightFor(width: metrics.sidebarWidth),
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: SidebarNavigation(
              items: widget.navItems,
              selectedIndex: widget.selectedIndex,
              onSelected: _handleNavSelected,
              collapsed: _sidebarCollapsed,
              onToggleCollapse: _toggleSidebar,
            ),
          ),
        if (isTablet)
          SizedBox(
            width: metrics.navigationRailWidth,
            child: ShellNavigationRail(
              items: widget.navItems,
              selectedIndex: widget.selectedIndex,
              onSelected: _handleNavSelected,
            ),
          ),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 0),
            child: _buildShellBody(
              isMobile: isMobile,
              isDesktop: isDesktop,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GradientBackground(
        showOrbs: false,
        child: ProductionExperienceLayer(
          key: _experienceKey,
          navItems: widget.navItems,
          onNavSelected: _handleNavSelected,
          quickActions: widget.quickActions,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: LayoutBuilder(
              builder: (context, constraints) {
                final viewportWidth = _safeWidth(
                  constraints.hasBoundedWidth ? constraints.maxWidth : null,
                  fallback: MediaQuery.sizeOf(context).width,
                );

                return SizedBox.expand(
                  child: _buildAdaptiveBody(viewportWidth),
                );
              },
            ),
            bottomNavigationBar: LayoutBuilder(
              builder: (context, constraints) {
                final viewportWidth = _safeWidth(
                  constraints.hasBoundedWidth ? constraints.maxWidth : null,
                  fallback: MediaQuery.sizeOf(context).width,
                );
                if (!AppBreakpoints.isMobile(viewportWidth)) {
                  return const SizedBox.shrink();
                }

                return ShellBottomNavigation(
                  items: widget.navItems,
                  selectedIndex: widget.selectedIndex,
                  onSelected: _handleNavSelected,
                );
              },
            ),
            floatingActionButton: widget.quickActions.isEmpty
                ? null
                : Builder(
                    builder: (context) {
                      final width = _safeWidth(
                        MediaQuery.sizeOf(context).width,
                        fallback: AppBreakpoints.tablet,
                      );
                      final isMobile = AppBreakpoints.isMobile(width);
                      return RepaintBoundary(
                        child: isMobile
                            ? FloatingActionButton(
                                onPressed: _openQuickActions,
                                child: const Icon(Icons.bolt_rounded),
                              )
                            : FloatingActionButton.extended(
                                onPressed: _openQuickActions,
                                icon: const Icon(Icons.bolt_rounded),
                                label: const Text('Actions'),
                              ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMobileNav(BuildContext context) async {
    if (_mobileNavOpen) return;
    _resetInteractions();
    _mobileNavOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.navItems.length; i++)
                  ListTile(
                    leading: Icon(
                      i == widget.selectedIndex
                          ? widget.navItems[i].activeIcon
                          : widget.navItems[i].icon,
                      color: i == widget.selectedIndex
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(widget.navItems[i].label),
                    selected: i == widget.selectedIndex,
                    onTap: () {
                      Navigator.pop(context);
                      _handleNavSelected(i);
                    },
                  ),
              ],
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        _mobileNavOpen = false;
        _resetInteractions();
      }
    }
  }
}

class _ShellLayoutMetrics {
  const _ShellLayoutMetrics({
    required this.viewportWidth,
    required this.breakpoint,
    required this.sidebarWidth,
    required this.navigationRailWidth,
  });

  static const double _tabletRailWidth = 88;

  final double viewportWidth;
  final AppBreakpoint breakpoint;
  final double sidebarWidth;
  final double navigationRailWidth;

  static _ShellLayoutMetrics fromViewport(
    double rawViewportWidth, {
    required bool sidebarCollapsed,
  }) {
    final viewportWidth = safeDimension(rawViewportWidth, fallback: 0);
    final breakpoint = AppBreakpoints.of(viewportWidth);
    final isDesktop =
        breakpoint == AppBreakpoint.desktop || breakpoint == AppBreakpoint.wide;
    final isTablet = breakpoint == AppBreakpoint.tablet;
    final sidebarWidth = isDesktop
        ? SidebarNavigation.safeWidth(
            collapsed: sidebarCollapsed,
            availableWidth: viewportWidth,
          )
        : 0.0;
    final railWidth = isTablet
        ? safeClamp(_tabletRailWidth, min: 0, max: viewportWidth)
        : 0.0;
    return _ShellLayoutMetrics(
      viewportWidth: viewportWidth,
      breakpoint: breakpoint,
      sidebarWidth: sidebarWidth,
      navigationRailWidth: railWidth,
    );
  }

  static double safeDimension(double? value, {required double fallback}) {
    final fallbackValue = fallback.isFinite && !fallback.isNaN ? fallback : 0.0;
    final raw =
        value != null && value.isFinite && !value.isNaN ? value : fallbackValue;
    if (!raw.isFinite || raw.isNaN || raw <= 0) return 0;
    return raw;
  }

  static double safeClamp(
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
}

class _DashboardLoadingSkeleton extends StatelessWidget {
  const _DashboardLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final shimmer =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 240,
            height: 32,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: AppSpacing.borderRadiusSm,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 360,
            height: 16,
            decoration: BoxDecoration(
              color: shimmer,
              borderRadius: AppSpacing.borderRadiusXs,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 200,
                  height: 120,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius: AppSpacing.borderRadiusMd,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Registers a scroll target for shell navigation.
class ShellSection extends StatelessWidget {
  const ShellSection({
    super.key,
    required this.sectionKey,
    required this.child,
  });

  final GlobalKey sectionKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: sectionKey, child: child);
  }
}
