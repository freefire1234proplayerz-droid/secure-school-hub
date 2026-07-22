import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/dashboard/dashboard_components.dart'
    hide DashboardSection;
import '../../widgets/dashboard/dashboard_grid.dart';
import '../../widgets/dashboard/dashboard_section.dart';
import '../../widgets/dashboard/kpi_stat_card.dart';
import '../../widgets/dashboard/quick_action_card.dart';
import '../../widgets/admin/user_management_module.dart';
import '../../widgets/design_system/app_button.dart';
import '../../widgets/communication/admin_communication_module.dart';
import '../../widgets/experience/production_experience.dart';
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
    'totalStudents': 1284,
    'presentToday': 1190,
    'attendancePercent': 93,
    'activeTeachers': 84,
    'alerts': 11,
    'feePending': 860000,
    'security': {
      'serverStatus': 'Online',
      'vpnStatus': 'Connected',
      'encryptedMessaging': 'Enabled',
      'suspiciousActivity': 2,
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

  String _money(num value) {
    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    }
    return '₹${value.toStringAsFixed(0)}';
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShellSection(
            sectionKey: _sectionKeys['overview']!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardPageHeader(
                  title: 'SecureSchoolHub Operations',
                  subtitle:
                      'A secure smart school operations platform for attendance, fees, communication, and infrastructure health.',
                  trailing: AppButton(
                    label: 'Sync live data',
                    icon: Icons.sync_rounded,
                    onPressed: _loadDashboard,
                    size: AppButtonSize.sm,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardGrid(
                  children: [
                    KPIStatCard(
                      label: 'Total students',
                      value: '${_data['totalStudents']}',
                      icon: Icons.groups_2_outlined,
                      color: colorScheme.primary,
                      detail: 'From Postgres student records',
                      isLoading: _loading,
                    ),
                    KPIStatCard(
                      label: 'Attendance today',
                      value: '${_data['attendancePercent']}%',
                      icon: Icons.fact_check_outlined,
                      color: Colors.teal,
                      detail: '${_data['presentToday']} marked present',
                      isLoading: _loading,
                    ),
                    KPIStatCard(
                      label: 'Active teachers',
                      value: '${_data['activeTeachers']}',
                      icon: Icons.badge_outlined,
                      color: Colors.indigo,
                      detail: 'Role-based teacher accounts',
                      isLoading: _loading,
                    ),
                    KPIStatCard(
                      label: 'Fee pending',
                      value: _money((_data['feePending'] as num?) ?? 0),
                      icon: Icons.currency_rupee,
                      color: Colors.deepOrange,
                      trend: '-12%',
                      detail: 'Payment reminders active',
                      isLoading: _loading,
                    ),
                    KPIStatCard(
                      label: 'Alerts',
                      value: '${_data['alerts']}',
                      icon: Icons.warning_amber_outlined,
                      color: Colors.red.shade600,
                      detail: 'Unread operational notifications',
                      isLoading: _loading,
                    ),
                  ],
                ),
              ],
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['analytics']!,
            child: DashboardSection(
              title: 'Attendance analytics',
              useGlassPanel: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AttendanceLineChart(
                    values: [89, 91, 94, 90, 93, 96],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ProgressRow(
                    label: 'Live QR attendance',
                    value: '${_data['attendancePercent']}%',
                    percent: (attendancePercent / 100).clamp(0, 1),
                  ),
                  const ProgressRow(
                    label: 'Homework completion',
                    value: '76%',
                    percent: 0.76,
                    color: Colors.teal,
                  ),
                  const ProgressRow(
                    label: 'Fee follow-up closed',
                    value: '68%',
                    percent: 0.68,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  IntelligentInsightsPanel(
                    audience: 'admin',
                    primaryScore: attendancePercent.toInt(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const PremiumAnalyticsPanel(
                    title: 'School-wide attendance and operations trend',
                    values: [88, 90, 91, 89, 93, 95, 94],
                  ),
                ],
              ),
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['actions']!,
            child: DashboardSection(
              title: 'Quick actions',
              useGlassPanel: false,
              child: DashboardGrid(
                minItemWidth: 260,
                children: [
                  QuickActionCard(
                    label: 'Generate student QRs',
                    description: 'Student QR records are synced from database',
                    icon: Icons.qr_code_2,
                    onTap: _loadDashboard,
                  ),
                  QuickActionCard(
                    label: 'Send emergency update',
                    description: 'Notification pipeline is ready for FCM',
                    icon: Icons.notification_important_outlined,
                    onTap: _loadDashboard,
                  ),
                  QuickActionCard(
                    label: 'Review fee pending',
                    description: 'Prioritize overdue family reminders',
                    icon: Icons.payments_outlined,
                    onTap: _loadDashboard,
                  ),
                  QuickActionCard(
                    label: 'Open security center',
                    description: 'Check infrastructure health status',
                    icon: Icons.security_outlined,
                    onTap: _loadDashboard,
                  ),
                ],
              ),
            ),
          ),
          ShellSection(
            sectionKey: GlobalKey(),
            child: const DashboardSection(
              title: 'Executive dashboard layout',
              useGlassPanel: false,
              animate: false,
              child: PersonalizableDashboardStrip(
                items: [
                  DashboardWidgetItem(
                    id: 'risk-heatmap',
                    title: 'Risk heatmap',
                    subtitle: 'Predictive absenteeism by class and route.',
                    icon: Icons.grid_view_rounded,
                    color: Colors.deepOrange,
                  ),
                  DashboardWidgetItem(
                    id: 'staff-workload',
                    title: 'Staff workload overview',
                    subtitle: 'Follow-ups, notices, grading, and support load.',
                    icon: Icons.badge_outlined,
                    color: Colors.indigo,
                  ),
                  DashboardWidgetItem(
                    id: 'ops',
                    title: 'Operational insights',
                    subtitle: 'SLA health, incidents, and queue pressure.',
                    icon: Icons.query_stats_rounded,
                    color: Colors.teal,
                  ),
                ],
              ),
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['users']!,
            child: const DashboardSection(
              title: 'User management',
              useGlassPanel: false,
              animate: false,
              child: UserManagementModule(),
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['security']!,
            child: DashboardSection(
              title: 'Security center',
              useGlassPanel: false,
              child: Column(
                children: [
                  ProgressRow(
                    label: 'Server health',
                    value: security['serverStatus']?.toString() ?? 'Online',
                    percent: 1,
                    color: Colors.teal,
                  ),
                  ProgressRow(
                    label: 'VPN protected admin access',
                    value: security['vpnStatus']?.toString() ?? 'Connected',
                    percent: 1,
                    color: Colors.indigo,
                  ),
                  ProgressRow(
                    label: 'Encrypted messaging',
                    value:
                        security['encryptedMessaging']?.toString() ?? 'Enabled',
                    percent: 1,
                  ),
                  ProgressRow(
                    label: 'Unusual activity review',
                    value: '${security['suspiciousActivity'] ?? 2} items',
                    percent: 0.22,
                    color: Colors.deepOrange,
                  ),
                ],
              ),
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['activity']!,
            child: const DashboardSection(
              title: 'Broadcasts & communications',
              useGlassPanel: false,
              animate: false,
              child: AdminCommunicationModule(),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
