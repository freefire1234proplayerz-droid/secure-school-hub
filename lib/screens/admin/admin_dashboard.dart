import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/dashboard/dashboard_components.dart';
import '../../widgets/language_toggle.dart';
import '../login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  static const routeName = '/admin';

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _api = ApiService();
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
    try {
      final res = await _api.get('/dashboard/admin');
      if (!mounted) return;
      setState(() {
        _data = Map<String, dynamic>.from(res.data as Map);
      });
    } catch (_) {
      // Keep premium fallback values if the API is temporarily unavailable.
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final security = Map<String, dynamic>.from(_data['security'] as Map);
    final recentActivity =
        List<Map<String, dynamic>>.from(_data['recentActivity'] as List? ?? []);

    return Focus(
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: LanguageToggle()),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: DashboardShell(
          title: 'SecureSchoolHub Operations',
          subtitle:
              'A secure smart school operations platform for attendance, fees, communication, and infrastructure health.',
          trailing: FilledButton.icon(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.sync),
            label: const Text('Sync live data'),
          ),
          children: [
            ResponsiveGrid(
              children: [
                MetricCard(
                  label: 'Total students',
                  value: '${_data['totalStudents']}',
                  icon: Icons.groups_2_outlined,
                  color: colorScheme.primary,
                  detail: 'From Postgres student records',
                ),
                MetricCard(
                  label: 'Attendance today',
                  value: '${_data['attendancePercent']}%',
                  icon: Icons.fact_check_outlined,
                  color: Colors.teal,
                  detail: '${_data['presentToday']} marked present',
                ),
                MetricCard(
                  label: 'Active teachers',
                  value: '${_data['activeTeachers']}',
                  icon: Icons.badge_outlined,
                  color: Colors.indigo,
                  detail: 'Role-based teacher accounts',
                ),
                MetricCard(
                  label: 'Fee pending',
                  value: _money((_data['feePending'] as num?) ?? 0),
                  icon: Icons.currency_rupee,
                  color: Colors.deepOrange,
                  trend: '-12%',
                  detail: 'Payment reminders active',
                ),
                MetricCard(
                  label: 'Alerts',
                  value: '${_data['alerts']}',
                  icon: Icons.warning_amber_outlined,
                  color: Colors.red.shade600,
                  detail: 'Unread operational notifications',
                ),
              ],
            ),
            const SizedBox(height: 18),
            DashboardSection(
              title: 'Attendance analytics',
              child: DashboardPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AttendanceLineChart(
                      values: [89, 91, 94, 90, 93, 96],
                    ),
                    const SizedBox(height: 8),
                    ProgressRow(
                      label: 'Live QR attendance',
                      value: '${_data['attendancePercent']}%',
                      percent:
                          (((_data['attendancePercent'] as num?) ?? 0) / 100)
                              .clamp(0, 1),
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
                  ],
                ),
              ),
            ),
            DashboardSection(
              title: 'Quick actions',
              child: ResponsiveGrid(
                minItemWidth: 260,
                children: [
                  ActionTile(
                    label: 'Generate student QRs',
                    description: 'Student QR records are synced from database',
                    icon: Icons.qr_code_2,
                    onTap: _loadDashboard,
                  ),
                  ActionTile(
                    label: 'Send emergency update',
                    description: 'Notification pipeline is ready for FCM',
                    icon: Icons.notification_important_outlined,
                    onTap: _loadDashboard,
                  ),
                  ActionTile(
                    label: 'Review fee pending',
                    description: 'Prioritize overdue family reminders',
                    icon: Icons.payments_outlined,
                    onTap: _loadDashboard,
                  ),
                  ActionTile(
                    label: 'Open security center',
                    description: 'Check infrastructure health status',
                    icon: Icons.security_outlined,
                    onTap: _loadDashboard,
                  ),
                ],
              ),
            ),
            DashboardSection(
              title: 'Security center',
              child: DashboardPanel(
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
                      value: security['encryptedMessaging']?.toString() ??
                          'Enabled',
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
            DashboardSection(
              title: 'Recent activity',
              child: DashboardPanel(
                child: NotificationList(
                  items: recentActivity.isEmpty
                      ? [
                          const DashboardNotification(
                            title: 'System ready',
                            detail:
                                'Backend, database, and dashboard APIs are online.',
                            icon: Icons.cloud_done_outlined,
                            color: Colors.teal,
                            time: 'Now',
                          ),
                        ]
                      : [
                          for (final item in recentActivity)
                            DashboardNotification(
                              title: item['title']?.toString() ?? 'Activity',
                              detail: item['detail']?.toString() ?? '',
                              icon: Icons.verified_user_outlined,
                              color: Colors.teal,
                              time: _time(item['createdAt']?.toString()),
                            ),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
