import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../services/frontend_experience_service.dart';
import '../../services/frontend_stability_service.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../dashboard/dashboard_grid.dart';
import '../design_system/app_button.dart';
import '../design_system/glass_card.dart';
import '../shell/shell_models.dart';

class ProductionExperienceLayer extends StatefulWidget {
  const ProductionExperienceLayer({
    super.key,
    required this.child,
    required this.navItems,
    required this.onNavSelected,
    required this.quickActions,
  });

  final Widget child;
  final List<ShellNavItem> navItems;
  final ValueChanged<int> onNavSelected;
  final List<ShellQuickAction> quickActions;

  @override
  ProductionExperienceLayerState createState() =>
      ProductionExperienceLayerState();
}

class ProductionExperienceLayerState extends State<ProductionExperienceLayer> {
  final _service = FrontendExperienceService.instance;
  final _stability = FrontendStabilityService.instance;
  bool _commandOpen = false;
  bool _activityOpen = false;
  bool _settingsOpen = false;

  @override
  void initState() {
    super.initState();
    _service.initialize();
    _stability.registerCleanup(closeOverlays);
  }

  @override
  void dispose() {
    _stability.unregisterCleanup(closeOverlays);
    _service.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppExperienceSnapshot>(
      valueListenable: _service.snapshot,
      builder: (context, snapshot, _) {
        return Stack(
          children: [
            widget.child,
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
              child: _OfflineSyncBanner(
                snapshot: snapshot,
                onSync: _service.syncPendingActions,
                onToggleOffline: () => _service.setConnectivityOverride(
                  !snapshot.online,
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              bottom: 88,
              child: RepaintBoundary(
                child: _FloatingExperienceDock(
                  pendingCount: snapshot.pendingCount,
                  onCommand: _openCommandPalette,
                  onActivity: () => _openExclusive(activity: true),
                  onSettings: () => _openExclusive(settings: true),
                ),
              ),
            ),
            if (_commandOpen)
              _CommandPaletteOverlay(
                navItems: widget.navItems,
                quickActions: widget.quickActions,
                onClose: () => setState(() => _commandOpen = false),
                onNavSelected: widget.onNavSelected,
              ),
            if (_activityOpen)
              _SidePanelOverlay(
                title: 'Activity center',
                onClose: () => setState(() => _activityOpen = false),
                child: GlobalActivityCenter(snapshot: snapshot),
              ),
            if (_settingsOpen)
              _SidePanelOverlay(
                title: 'Settings',
                onClose: () => setState(() => _settingsOpen = false),
                child: SettingsCenter(
                  preferences: snapshot.preferences,
                  onChanged: _service.savePreferences,
                ),
              ),
          ],
        );
      },
    );
  }

  void openCommandPalette() {
    _openCommandPalette();
  }

  void closeOverlays() {
    if (!_commandOpen && !_activityOpen && !_settingsOpen) return;
    setState(() {
      _commandOpen = false;
      _activityOpen = false;
      _settingsOpen = false;
    });
  }

  void _openCommandPalette() {
    FocusManager.instance.primaryFocus?.unfocus();
    _openExclusive(command: true);
  }

  void _openExclusive({
    bool command = false,
    bool activity = false,
    bool settings = false,
  }) {
    if (_commandOpen == command &&
        _activityOpen == activity &&
        _settingsOpen == settings) {
      return;
    }
    setState(() {
      _commandOpen = command;
      _activityOpen = activity;
      _settingsOpen = settings;
    });
  }
}

class _OfflineSyncBanner extends StatelessWidget {
  const _OfflineSyncBanner({
    required this.snapshot,
    required this.onSync,
    required this.onToggleOffline,
  });

  final AppExperienceSnapshot snapshot;
  final VoidCallback onSync;
  final VoidCallback onToggleOffline;

  @override
  Widget build(BuildContext context) {
    if (snapshot.online && snapshot.pendingCount == 0 && !snapshot.syncing) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    final status = snapshot.syncing
        ? 'Syncing ${(snapshot.syncProgress * 100).round()}%'
        : snapshot.online
            ? '${snapshot.pendingCount} queued action(s)'
            : 'Offline mode active';

    return IgnorePointer(
      ignoring: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Material(
            elevation: 10,
            color: scheme.surface.withValues(alpha: 0.96),
            borderRadius: AppSpacing.borderRadiusMd,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        snapshot.online
                            ? Icons.cloud_sync_outlined
                            : Icons.cloud_off_outlined,
                        color:
                            snapshot.online ? Colors.teal : Colors.deepOrange,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          status,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      TextButton(
                        onPressed: onSync,
                        child: const Text('Retry sync'),
                      ),
                    ],
                  ),
                  if (snapshot.syncing) ...[
                    const SizedBox(height: AppSpacing.xs),
                    LinearProgressIndicator(value: snapshot.syncProgress),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingExperienceDock extends StatelessWidget {
  const _FloatingExperienceDock({
    required this.pendingCount,
    required this.onCommand,
    required this.onActivity,
    required this.onSettings,
  });

  final int pendingCount;
  final VoidCallback onCommand;
  final VoidCallback onActivity;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: AppSpacing.borderRadiusLg,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DockButton(
              tooltip: 'Command palette',
              icon: Icons.manage_search_rounded,
              onPressed: onCommand,
            ),
            Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: _DockButton(
                tooltip: 'Activity center',
                icon: Icons.dynamic_feed_rounded,
                onPressed: onActivity,
              ),
            ),
            _DockButton(
              tooltip: 'Settings',
              icon: Icons.tune_rounded,
              onPressed: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

class _CommandPaletteOverlay extends StatefulWidget {
  const _CommandPaletteOverlay({
    required this.navItems,
    required this.quickActions,
    required this.onClose,
    required this.onNavSelected,
  });

  final List<ShellNavItem> navItems;
  final List<ShellQuickAction> quickActions;
  final VoidCallback onClose;
  final ValueChanged<int> onNavSelected;

  @override
  State<_CommandPaletteOverlay> createState() => _CommandPaletteOverlayState();
}

class _CommandPaletteOverlayState extends State<_CommandPaletteOverlay> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commands = <_CommandItem>[
      for (var i = 0; i < widget.navItems.length; i++)
        _CommandItem(
          label: widget.navItems[i].label,
          subtitle: 'Navigate to dashboard section',
          icon: widget.navItems[i].icon,
          onTap: () {
            widget.onNavSelected(i);
            widget.onClose();
          },
        ),
      for (final action in widget.quickActions)
        _CommandItem(
          label: action.label,
          subtitle: action.description ?? 'Run quick action',
          icon: action.icon,
          onTap: () {
            widget.onClose();
            action.onTap();
          },
        ),
    ].where((item) {
      final q = _query.trim().toLowerCase();
      return q.isEmpty ||
          item.label.toLowerCase().contains(q) ||
          item.subtitle.toLowerCase().contains(q);
    }).toList();

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.24),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onClose,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 640, maxHeight: 560),
                child: GlassCard(
                  variant: GlassCardVariant.elevated,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Search navigation, actions, reports...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) {
                          if (commands.isNotEmpty) commands.first.onTap();
                        },
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: commands.length,
                          itemBuilder: (context, index) {
                            final command = commands[index];
                            return ListTile(
                              leading: Icon(command.icon),
                              title: Text(command.label),
                              subtitle: Text(command.subtitle),
                              onTap: command.onTap,
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.onClose,
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandItem {
  const _CommandItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _SidePanelOverlay extends StatelessWidget {
  const _SidePanelOverlay({
    required this.title,
    required this.child,
    required this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              elevation: 16,
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                child: SizedBox(
                  width: math.min(MediaQuery.sizeOf(context).width, 420),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        trailing: IconButton(
                          tooltip: 'Close',
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlobalActivityCenter extends StatelessWidget {
  const GlobalActivityCenter({super.key, required this.snapshot});

  final AppExperienceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _LiveConnectionCard(snapshot: snapshot),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Recent actions',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final activity in snapshot.activities)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: activity.color.withValues(alpha: 0.14),
              child: Icon(activity.icon, color: activity.color),
            ),
            title: Text(activity.title),
            subtitle: Text(activity.detail),
          ),
        if (snapshot.pendingActions.isNotEmpty) ...[
          const Divider(),
          Text(
            'Queued offline',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          for (final action in snapshot.pendingActions)
            ListTile(
              leading: const Icon(Icons.schedule_send_outlined),
              title: Text(action.title),
              subtitle:
                  Text('${action.type.name} • ${action.attempts} retries'),
            ),
        ],
      ],
    );
  }
}

class _LiveConnectionCard extends StatelessWidget {
  const _LiveConnectionCard({required this.snapshot});

  final AppExperienceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final color = snapshot.online ? Colors.teal : Colors.deepOrange;
    return GlassCard(
      variant: GlassCardVariant.flat,
      child: Row(
        children: [
          AppPulse(
            minScale: 0.86,
            child: Icon(Icons.circle, color: color, size: 14),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              snapshot.online
                  ? 'Live heartbeat connected'
                  : 'Offline with local queue',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsCenter extends StatelessWidget {
  const SettingsCenter({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  final UserExperiencePreferences preferences;
  final ValueChanged<UserExperiencePreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Appearance',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final color in [
              Colors.indigo,
              Colors.teal,
              Colors.deepOrange,
              Colors.pink,
            ])
              ChoiceChip(
                label: Text(_colorName(color)),
                selected:
                    preferences.accentColor.toARGB32() == color.toARGB32(),
                onSelected: (_) => onChanged(
                  preferences.copyWith(accentColor: color),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<DashboardDensity>(
          segments: const [
            ButtonSegment(
              value: DashboardDensity.comfortable,
              label: Text('Comfortable'),
              icon: Icon(Icons.view_agenda_outlined),
            ),
            ButtonSegment(
              value: DashboardDensity.compact,
              label: Text('Compact'),
              icon: Icon(Icons.density_small_outlined),
            ),
          ],
          selected: {preferences.density},
          onSelectionChanged: (value) {
            onChanged(preferences.copyWith(density: value.first));
          },
        ),
        const Divider(height: AppSpacing.xl),
        SwitchListTile(
          value: preferences.pushBanners,
          onChanged: (value) => onChanged(
            preferences.copyWith(pushBanners: value),
          ),
          title: const Text('Push-style in-app banners'),
          secondary: const Icon(Icons.notifications_active_outlined),
        ),
        SwitchListTile(
          value: preferences.reducedMotion,
          onChanged: (value) => onChanged(
            preferences.copyWith(reducedMotion: value),
          ),
          title: const Text('Reduced motion'),
          secondary: const Icon(Icons.motion_photos_off_outlined),
        ),
        SwitchListTile(
          value: preferences.highContrast,
          onChanged: (value) => onChanged(
            preferences.copyWith(highContrast: value),
          ),
          title: const Text('High contrast'),
          secondary: const Icon(Icons.contrast_rounded),
        ),
        SwitchListTile(
          value: preferences.scannerHaptics,
          onChanged: (value) => onChanged(
            preferences.copyWith(scannerHaptics: value),
          ),
          title: const Text('Scanner success haptics'),
          secondary: const Icon(Icons.qr_code_scanner_rounded),
        ),
      ],
    );
  }

  String _colorName(Color color) {
    if (color == Colors.teal) return 'Teal';
    if (color == Colors.deepOrange) return 'Orange';
    if (color == Colors.pink) return 'Pink';
    return 'Indigo';
  }
}

class IntelligentInsightsPanel extends StatelessWidget {
  const IntelligentInsightsPanel({
    super.key,
    required this.audience,
    required this.primaryScore,
  });

  final String audience;
  final int primaryScore;

  @override
  Widget build(BuildContext context) {
    final insights = _insightsFor(audience, primaryScore);
    return DashboardGrid(
      minItemWidth: 240,
      children: [
        for (final insight in insights)
          GlassCard(
            variant: GlassCardVariant.elevated,
            child: Semantics(
              label: '${insight.title}: ${insight.value}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(insight.icon, color: insight.color),
                      const Spacer(),
                      Text(
                        insight.value,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: insight.color,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    insight.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    insight.detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LinearProgressIndicator(
                    value: insight.percent,
                    color: insight.color,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<_InsightModel> _insightsFor(String audience, int score) {
    if (audience == 'parent') {
      return [
        _InsightModel(
          title: 'Attendance consistency',
          value: '$score%',
          detail:
              'Prediction expects a stable week if arrival remains before 8:10.',
          icon: Icons.verified_user_outlined,
          color: Colors.teal,
          percent: score / 100,
        ),
        const _InsightModel(
          title: 'Learning momentum',
          value: '+8%',
          detail: 'Homework completion and grade trend are moving together.',
          icon: Icons.trending_up_rounded,
          color: Colors.indigo,
          percent: 0.78,
        ),
        const _InsightModel(
          title: 'Suggested focus',
          value: 'Math',
          detail:
              'Ten minutes of daily revision should lift the next quiz band.',
          icon: Icons.auto_awesome_rounded,
          color: Colors.deepOrange,
          percent: 0.62,
        ),
      ];
    }
    if (audience == 'admin') {
      return [
        _InsightModel(
          title: 'Absenteeism risk',
          value: '${100 - score}%',
          detail: 'Class 6 and transport route B need early intervention.',
          icon: Icons.warning_amber_outlined,
          color: Colors.deepOrange,
          percent: (100 - score) / 100,
        ),
        const _InsightModel(
          title: 'Staff workload',
          value: 'Balanced',
          detail: 'Four teachers are above the weekly follow-up threshold.',
          icon: Icons.workspaces_outline,
          color: Colors.indigo,
          percent: 0.71,
        ),
        const _InsightModel(
          title: 'Operations health',
          value: '94%',
          detail: 'Attendance, notices, and fee follow-ups are within SLA.',
          icon: Icons.health_and_safety_outlined,
          color: Colors.teal,
          percent: 0.94,
        ),
      ];
    }
    return [
      _InsightModel(
        title: 'Attendance risk',
        value: '${100 - score}%',
        detail: 'Three students may need a parent nudge before Friday.',
        icon: Icons.psychology_alt_outlined,
        color: Colors.deepOrange,
        percent: (100 - score) / 100,
      ),
      const _InsightModel(
        title: 'Class engagement',
        value: '82%',
        detail: 'Notice opens and homework responses are above baseline.',
        icon: Icons.insights_rounded,
        color: Colors.teal,
        percent: 0.82,
      ),
      const _InsightModel(
        title: 'Homework trend',
        value: '+12%',
        detail: 'Completion is improving after shorter assignments.',
        icon: Icons.assignment_turned_in_outlined,
        color: Colors.indigo,
        percent: 0.76,
      ),
    ];
  }
}

class _InsightModel {
  const _InsightModel({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.percent,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final double percent;
}

class PremiumAnalyticsPanel extends StatelessWidget {
  const PremiumAnalyticsPanel({
    super.key,
    required this.title,
    required this.values,
  });

  final String title;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.query_stats_rounded),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.35),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(),
                  rightTitles: AxisTitles(),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < values.length; i++)
                        FlSpot(i.toDouble(), values[i]),
                    ],
                    isCurved: true,
                    barWidth: 3,
                    color: Theme.of(context).colorScheme.primary,
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PersonalizableDashboardStrip extends StatefulWidget {
  const PersonalizableDashboardStrip({
    super.key,
    required this.items,
  });

  final List<DashboardWidgetItem> items;

  @override
  State<PersonalizableDashboardStrip> createState() =>
      _PersonalizableDashboardStripState();
}

class _PersonalizableDashboardStripState
    extends State<PersonalizableDashboardStrip> {
  late final List<DashboardWidgetItem> _items = List.of(widget.items);
  final Set<String> _pinned = {};

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _items.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final item = _items[index];
        final pinned = _pinned.contains(item.id);
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GlassCard(
            variant: GlassCardVariant.flat,
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_indicator_rounded),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(item.icon, color: item.color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(item.subtitle),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: pinned ? 'Unpin widget' : 'Pin widget',
                  onPressed: () {
                    setState(() {
                      pinned ? _pinned.remove(item.id) : _pinned.add(item.id);
                    });
                  },
                  icon: Icon(
                    pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DashboardWidgetItem {
  const DashboardWidgetItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class MediaExperiencePanel extends StatefulWidget {
  const MediaExperiencePanel({super.key});

  @override
  State<MediaExperiencePanel> createState() => _MediaExperiencePanelState();
}

class _MediaExperiencePanelState extends State<MediaExperiencePanel> {
  double _progress = 0.42;

  @override
  Widget build(BuildContext context) {
    return DashboardGrid(
      minItemWidth: 250,
      children: [
        GlassCard(
          variant: GlassCardVariant.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cloud_upload_outlined),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Drag files here',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Text(
                  'Worksheets, notices, receipts, and reports queue locally.'),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Simulate upload',
                icon: Icons.upload_file_outlined,
                size: AppButtonSize.sm,
                onPressed: () {
                  setState(() => _progress = (_progress + 0.2).clamp(0, 1));
                  FrontendExperienceService.instance.queueAction(
                    PendingActionType.upload,
                    title: 'Queued attachment upload',
                  );
                },
              ),
            ],
          ),
        ),
        const _AttachmentPreviewCard(
          title: 'Attendance report',
          subtitle: 'PDF • ready to download',
          icon: Icons.picture_as_pdf_outlined,
          color: Colors.red,
        ),
        const _AttachmentPreviewCard(
          title: 'QR export bundle',
          subtitle: 'Student QR cards • share ready',
          icon: Icons.qr_code_2_rounded,
          color: Colors.indigo,
        ),
      ],
    );
  }
}

class _AttachmentPreviewCard extends StatelessWidget {
  const _AttachmentPreviewCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.flat,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(subtitle),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Download',
            onPressed: () {},
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
    );
  }
}
