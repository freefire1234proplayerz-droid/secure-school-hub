import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/design_system/app_button.dart';
import '../../widgets/design_system/glass_card.dart';
import '../../widgets/admin/user_management_module.dart';
import '../../widgets/communication/admin_communication_module.dart';
import '../../widgets/shell/app_shell.dart';
import '../login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  static const routeName = '/admin';

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _api = ApiService();
  int _selectedNav = 0;
  bool _loading = true;

  final _sectionKeys = <String, GlobalKey>{
    for (final id in [
      'overview',
      'analytics',
      'actions',
      'users',
      'security',
      'activity'
    ])
      id: GlobalKey(),
  };

  Map<String, dynamic> _data = {
    'totalStudents': 0,
    'presentToday': 0,
    'attendancePercent': 0,
    'activeTeachers': 0,
    'alerts': 0,
    'feePending': 0,
    'security': {
      'serverStatus': 'Online',
      'vpnStatus': 'Configured',
      'encryptedMessaging': 'Enabled',
      'suspiciousActivity': 0,
    },
    'recentActivity': [],
  };

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/dashboard/admin');
      if (!mounted) return;
      setState(() {
        _data = Map<String, dynamic>.from(res.data as Map);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthService>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _money(num? value) {
    final intVal = (value ?? 0).toInt();
    if (intVal >= 100000) {
      return '₹${(intVal / 100000).toStringAsFixed(1)}L';
    }
    return '₹${intVal.toStringAsFixed(0)}';
  }

  String _time(String? raw) {
    final parsed = DateTime.tryParse(raw ?? '');
    if (parsed == null) return 'Now';
    final local = parsed.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  List<ShellNotification> _shellNotifications() {
    final recent =
        List<Map<String, dynamic>>.from(_data['recentActivity'] as List? ?? []);
    if (recent.isEmpty) {
      return const [
        ShellNotification(
          id: 'system',
          title: 'System ready',
          body: 'Backend, database, and dashboard APIs are online.',
          icon: Icons.cloud_done_outlined,
          color: Colors.teal,
          time: 'Now',
        ),
      ];
    }
    return [
      for (var i = 0; i < recent.length; i++)
        ShellNotification(
          id: 'activity-$i',
          title: recent[i]['title']?.toString() ?? 'Activity',
          body: recent[i]['detail']?.toString() ?? '',
          icon: Icons.verified_user_outlined,
          color: Colors.teal,
          time: _time(recent[i]['createdAt']?.toString()),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final security = Map<String, dynamic>.from(_data['security'] as Map);
    final attendancePercent = (_data['attendancePercent'] as num?) ?? 0;

    return AppShell(
      title: 'Admin Operations',
      navItems: ShellNavConfig.admin,
      selectedIndex: _selectedNav,
      onNavSelected: (i) => setState(() => _selectedNav = i),
      sectionKeys: _sectionKeys,
      notifications: _shellNotifications(),
      onLogout: () => _logout(context),
      onRefresh: _loadDashboard,
      isLoading: _loading,
      quickActions: [
        ShellQuickAction(
          label: 'Sync live data',
          icon: Icons.sync_rounded,
          onTap: _loadDashboard,
        ),
        ShellQuickAction(
          label: 'Emergency update',
          icon: Icons.notification_important_outlined,
          onTap: _loadDashboard,
        ),
        ShellQuickAction(
          label: 'Manage users',
          icon: Icons.manage_accounts_outlined,
          onTap: _loadDashboard,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildKpiCards(colorScheme),
                    const SizedBox(height: 24),
                    _buildAdminQuickActions(),
                    const SizedBox(height: 24),
                    _buildSecurityStatus(security),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  key: _sectionKeys['analytics']!,
                  title: 'Attendance analytics',
                  child: _buildAnalytics(attendancePercent),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  key: _sectionKeys['users']!,
                  title: 'User management',
                  child: const UserManagementModule(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: _buildSection(
                  key: _sectionKeys['security']!,
                  title: 'Security center',
                  child: _buildSecurityDetails(security),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  key: _sectionKeys['activity']!,
                  title: 'Broadcasts & communications',
                  child: const AdminCommunicationModule(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SecureSchoolHub Operations',
                style: AppTextStyles.pageTitle(Theme.of(context).textTheme),
              ),
              const SizedBox(height: 4),
              Text(
                'A secure smart school operations platform for attendance, fees, communication, and infrastructure health.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        AppButton(
          label: 'Sync live data',
          icon: Icons.sync_rounded,
          onPressed: _loadDashboard,
          size: AppButtonSize.sm,
        ),
      ],
    );
  }

  Widget _buildKpiCards(ColorScheme colorScheme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _KpiCard(
          label: 'Total students',
          value: '${_data['totalStudents']}',
          icon: Icons.groups_2_outlined,
          color: colorScheme.primary,
          detail: 'From Postgres student records',
          isLoading: _loading,
        ),
        _KpiCard(
          label: 'Attendance today',
          value: '${_data['attendancePercent']}%',
          icon: Icons.fact_check_outlined,
          color: Colors.teal,
          detail: '${_data['presentToday']} marked present',
          isLoading: _loading,
        ),
        _KpiCard(
          label: 'Active teachers',
          value: '${_data['activeTeachers']}',
          icon: Icons.badge_outlined,
          color: Colors.indigo,
          detail: 'Role-based teacher accounts',
          isLoading: _loading,
        ),
        _KpiCard(
          label: 'Fee pending',
          value: _money((_data['feePending'] as num?) ?? 0),
          icon: Icons.currency_rupee,
          color: Colors.deepOrange,
          detail: 'Payment reminders active',
          isLoading: _loading,
        ),
        _KpiCard(
          label: 'Alerts',
          value: '${_data['alerts']}',
          icon: Icons.warning_amber_outlined,
          color: Colors.red.shade600,
          detail: 'Unread operational notifications',
          isLoading: _loading,
        ),
      ],
    );
  }

  Widget _buildAdminQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionCard(
              label: 'Send emergency update',
              description: 'Broadcast urgent notification to all',
              icon: Icons.notification_important_outlined,
              onTap: _loadDashboard,
            ),
            _ActionCard(
              label: 'Review fee pending',
              description: 'Prioritize overdue family reminders',
              icon: Icons.payments_outlined,
              onTap: _loadDashboard,
            ),
            _ActionCard(
              label: 'Run infrastructure check',
              description: 'Basic server-side health monitoring',
              icon: Icons.health_and_safety_outlined,
              onTap: _loadDashboard,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurityStatus(Map<String, dynamic> security) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ProgressRow(
            label: 'Server health',
            value: security['serverStatus']?.toString() ?? 'Online',
            percent: 1,
            color: Colors.teal,
          ),
          _ProgressRow(
            label: 'VPN protected admin access',
            value: security['vpnStatus']?.toString() ?? 'Configured',
            percent: 1,
            color: Colors.indigo,
          ),
          _ProgressRow(
            label: 'Encrypted messaging',
            value: security['encryptedMessaging']?.toString() ?? 'Enabled',
            percent: 1,
            color: Colors.teal,
          ),
          _ProgressRow(
            label: 'Unusual activity review',
            value: '${security['suspiciousActivity'] ?? 0} items',
            percent: 0.1,
            color: Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics(num attendancePercent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AttendanceChart(values: [89, 91, 94, 90, 93, 96]),
        const SizedBox(height: 16),
        _ProgressRow(
          label: 'Live QR attendance',
          value: '$attendancePercent%',
          percent: (attendancePercent / 100).clamp(0, 1),
        ),
        _ProgressRow(
          label: 'Homework completion',
          value: '76%',
          percent: 0.76,
          color: Colors.teal,
        ),
        _ProgressRow(
          label: 'Fee follow-up closed',
          value: '68%',
          percent: 0.68,
          color: Colors.indigo,
        ),
        const SizedBox(height: 24),
        _AnalyticsChart(values: [88, 90, 91, 89, 93, 95, 94]),
      ],
    );
  }

  Widget _buildSecurityDetails(Map<String, dynamic> security) {
    return Column(
      children: [
        _ProgressRow(
          label: 'Server health',
          value: security['serverStatus']?.toString() ?? 'Online',
          percent: 1,
          color: Colors.teal,
        ),
        _ProgressRow(
          label: 'VPN protected admin access',
          value: security['vpnStatus']?.toString() ?? 'Configured',
          percent: 1,
          color: Colors.indigo,
        ),
        _ProgressRow(
          label: 'Encrypted messaging',
          value: security['encryptedMessaging']?.toString() ?? 'Enabled',
          percent: 1,
          color: Colors.teal,
        ),
        _ProgressRow(
          label: 'Unusual activity review',
          value: '${security['suspiciousActivity'] ?? 0} items',
          percent: 0.1,
          color: Colors.deepOrange,
        ),
      ],
    );
  }

  Widget _buildSection({
    required GlobalKey key,
    required String title,
    Widget? action,
    required Widget child,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (trend != null && !isLoading)
                  Text(
                    trend!,
                    style: textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.percent,
    this.color,
  });

  final String label;
  final String value;
  final double percent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = color ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: percent.clamp(0, 1),
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 320),
      child: GlassCard(
        variant: GlassCardVariant.elevated,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: colorScheme.primary, size: 24),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceChart extends StatelessWidget {
  const _AttendanceChart({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: 70,
          maxY: 100,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 10,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}%',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[index],
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots
                  .map(
                    (spot) => LineTooltipItem(
                      '${spot.y.toStringAsFixed(0)}%',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i].toDouble()),
              ],
              isCurved: true,
              barWidth: 3,
              color: colorScheme.primary,
              belowBarData: BarAreaData(
                show: true,
                color: colorScheme.primary.withValues(alpha: 0.12),
              ),
              dotData: FlDotData(
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: colorScheme.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsChart extends StatelessWidget {
  const _AnalyticsChart({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'School-wide attendance and operations trend',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.query_stats_rounded),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
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
                        FlSpot(i.toDouble(), values[i].toDouble()),
                    ],
                    isCurved: true,
                    barWidth: 3,
                    color: colorScheme.primary,
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.12),
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