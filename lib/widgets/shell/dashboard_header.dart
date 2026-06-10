import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

import '../../theme/app_animations.dart';
import 'notification_panel.dart';
import 'profile_menu.dart';
import 'shell_models.dart';

/// Sticky top app bar with search, notifications, and profile menu.
class DashboardHeader extends StatefulWidget {
  const DashboardHeader({
    super.key,
    required this.title,
    this.onMenuToggle,
    this.showMenuButton = false,
    this.notifications = const [],
    this.onLogout,
    this.onRefresh,
    this.onSearch,
    this.searchHint = 'Search dashboard…',
  });

  final String title;
  final VoidCallback? onMenuToggle;
  final bool showMenuButton;
  final List<ShellNotification> notifications;
  final VoidCallback? onLogout;
  final VoidCallback? onRefresh;
  final ValueChanged<String>? onSearch;
  final String searchHint;

  @override
  State<DashboardHeader> createState() => DashboardHeaderState();
}

class DashboardHeaderState extends State<DashboardHeader>
    with WidgetsBindingObserver {
  final _searchFocus = FocusNode();
  final _searchController = TextEditingController();
  final _notificationKey = GlobalKey();
  OverlayEntry? _notificationOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    _closeNotifications();
  }

  @override
  void didUpdateWidget(covariant DashboardHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifications != widget.notifications) {
      _closeNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _closeNotifications();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void closeOverlays() {
    _closeNotifications();
  }

  void focusSearch() {
    _closeNotifications();
    _searchFocus.requestFocus();
  }

  void _toggleNotifications() {
    if (_notificationOverlay != null) {
      _closeNotifications();
      return;
    }

    final overlay = Overlay.of(context);
    final renderBox =
        _notificationKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final screenWidth = _safeDimension(MediaQuery.sizeOf(context).width);
    final buttonWidth = _safeDimension(renderBox.size.width);
    final panelWidth = _safeClamp(screenWidth - AppSpacing.md, 0, 360);
    final rawRight = screenWidth - offset.dx - buttonWidth;
    final panelRight = _safeClamp(
      rawRight,
      0,
      screenWidth > AppSpacing.xs ? screenWidth - AppSpacing.xs : 0,
    );

    _notificationOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy + renderBox.size.height + 8,
        right: panelRight,
        child: RepaintBoundary(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 0,
              maxWidth: panelWidth,
            ),
            child: NotificationPanel(
              notifications: widget.notifications,
              onClose: _closeNotifications,
            ),
          ),
        ),
      ),
    );

    overlay.insert(_notificationOverlay!);
  }

  void _closeNotifications() {
    final overlay = _notificationOverlay;
    if (overlay != null && overlay.mounted) {
      overlay.remove();
    }
    _notificationOverlay = null;
  }

  double _safeDimension(double value) {
    if (!value.isFinite || value.isNaN || value <= 0) return 0;
    return value;
  }

  double _safeClamp(double value, double min, double max) {
    final lower = min.isFinite && !min.isNaN ? min : 0.0;
    final safeMax = max.isFinite && !max.isNaN ? max : lower;
    final upper = safeMax >= lower ? safeMax : lower;
    final raw = value.isFinite && !value.isNaN ? value : lower;
    return raw.clamp(lower, upper).toDouble();
  }

  int get _unreadCount => widget.notifications.where((n) => n.isUnread).length;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screenWidth = _safeDimension(MediaQuery.sizeOf(context).width);
    final isCompact = screenWidth < AppBreakpoints.tablet;

    return Material(
      elevation: 0,
      color: scheme.surface.withValues(alpha: 0.88),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? AppSpacing.sm : AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                if (widget.showMenuButton)
                  IconButton(
                    tooltip: 'Toggle navigation',
                    onPressed: widget.onMenuToggle,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                if (!isCompact)
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                Expanded(
                  flex: isCompact ? 1 : 3,
                  child: _SearchField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    hint: widget.searchHint,
                    onChanged: widget.onSearch,
                    onSubmitted: widget.onSearch,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                KeyedSubtree(
                  key: _notificationKey,
                  child: NotificationBell(
                    unreadCount: _unreadCount,
                    onPressed: _toggleNotifications,
                  ),
                ),
                if (widget.onLogout != null)
                  ProfileMenu(
                    onLogout: widget.onLogout!,
                    onRefresh: widget.onRefresh,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < AppBreakpoints.desktop;

    return AnimatedContainer(
      duration: AppAnimations.fast,
      height: 42,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: _focused
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: isCompact
              ? null
              : Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ShortcutChip(
                        label: defaultTargetPlatform == TargetPlatform.macOS
                            ? '⌘K'
                            : 'Ctrl+K',
                      ),
                    ],
                  ),
                ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: AppSpacing.borderRadiusXs,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
            ),
      ),
    );
  }
}
