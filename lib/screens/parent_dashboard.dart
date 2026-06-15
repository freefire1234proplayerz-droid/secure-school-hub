import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/frontend_experience_service.dart';
import '../utils/json_num.dart';
import '../theme/app_spacing.dart';
import '../widgets/dashboard/dashboard_components.dart' hide DashboardSection;
import '../widgets/dashboard/dashboard_grid.dart';
import '../widgets/dashboard/dashboard_section.dart';
import '../widgets/dashboard/kpi_stat_card.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/attendance/attendance_models.dart';
import '../widgets/attendance/parent_attendance_module.dart';
import '../widgets/communication/parent_communication_module.dart';
import '../widgets/experience/production_experience.dart';
import '../widgets/shell/app_shell.dart';
import 'login_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  static const routeName = '/parent';

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final ApiService _api = ApiService();
  bool _loading = true;
  int _selectedNav = 0;

  final _sectionKeys = <String, GlobalKey>{
    for (final id in [
      'overview',
      'attendance',
      'grades',
      'homework',
      'messages',
    ])
      id: GlobalKey(),
  };

  List<DashboardNotification> _notifications = const [
    DashboardNotification(
      title: 'Child entered school',
      detail: 'Aarav was marked present from QR attendance.',
      icon: Icons.verified_user_outlined,
      color: Colors.teal,
      time: 'Demo',
    ),
    DashboardNotification(
      title: 'Homework assigned',
      detail: 'Math practice is due tomorrow evening.',
      icon: Icons.assignment_outlined,
      color: Colors.indigo,
      time: 'Demo',
    ),
    DashboardNotification(
      title: 'Fee reminder',
      detail: 'Transport fee payment is pending.',
      icon: Icons.receipt_long_outlined,
      color: Colors.deepOrange,
      time: 'Demo',
    ),
  ];
  Map<String, dynamic> _dashboard = {
    'childName': 'Aarav Sharma',
    'attendancePercent': 94,
    'gradeAverage': 86,
    'feeReminders': 1,
    'grades': [],
    'homework': [],
  };

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  String _formatError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
      return e.message ?? 'Request failed';
    }
    return e.toString();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _loadGrades() async {
    try {
      final res = await _api.get('/grades');
      final grades = List<Map<String, dynamic>>.from(
        res.data['grades'] as List<dynamic>? ?? [],
      );
      if (!mounted) return;
      setState(() {
        _dashboard = {..._dashboard, 'grades': grades};
      });
      _showSnack('Grades refreshed from school records.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed: ${_formatError(e)}', isError: true);
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() => _loading = true);
    await _loadDashboard();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _uploadFeeProof() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    try {
      await _api.post('/fees/attach', data: {
        'fileName': file.name,
        'size': file.size,
      });
      if (!mounted) return;
      _showSnack('Fee proof sent to teacher: ${file.name}');
      await _refreshDashboard();
    } catch (e) {
      if (!mounted) return;
      await FrontendExperienceService.instance.queueAction(
        PendingActionType.upload,
        title: 'Offline fee proof: ${file.name}',
        payload: {'fileName': file.name, 'size': file.size},
      );
      _showSnack('Upload failed: ${_formatError(e)}', isError: true);
    }
  }

  Future<void> _loadDashboard() async {
    try {
      final res = await _api.get('/dashboard/parent');
      if (!mounted) return;
      final data = Map<String, dynamic>.from(res.data as Map);
      final rows = List<Map<String, dynamic>>.from(
        data['notifications'] as List<dynamic>? ?? [],
      );
      setState(() {
        _dashboard = data;
        if (rows.isNotEmpty) {
          _notifications = rows.map((row) {
            final type = row['type']?.toString();
            return DashboardNotification(
              title: row['title']?.toString() ?? 'School update',
              detail: row['body']?.toString() ?? '',
              icon: type == 'attendance'
                  ? Icons.verified_user_outlined
                  : Icons.notifications_none,
              color: type == 'attendance' ? Colors.teal : Colors.indigo,
              time: _shortTime(row['created_at']?.toString()),
            );
          }).toList();
        }
      });
    } catch (_) {
      await _loadNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final res = await _api.get('/attendance/notifications');
      final rows = List<Map<String, dynamic>>.from(
        res.data['notifications'] as List<dynamic>,
      );
      if (!mounted || rows.isEmpty) return;
      setState(() {
        _notifications = rows.map((row) {
          final type = row['type']?.toString();
          return DashboardNotification(
            title: row['title']?.toString() ?? 'School update',
            detail: row['body']?.toString() ?? '',
            icon: type == 'attendance'
                ? Icons.verified_user_outlined
                : Icons.notifications_none,
            color: type == 'attendance' ? Colors.teal : Colors.indigo,
            time: _shortTime(row['created_at']?.toString()),
          );
        }).toList();
      });
    } catch (_) {
      // Keep the premium fallback notifications if the API is not reachable.
    }
  }

  String _shortTime(String? raw) {
    if (raw == null) return 'Now';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 'Now';
    final local = parsed.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  double _gradePercent(Map<String, dynamic> grade) {
    final score = asDouble(grade['score']);
    final maxScore = asDouble(grade['max_score'], 100);
    if (maxScore == 0) return 0;
    return (score / maxScore).clamp(0, 1);
  }

  List<ShellNotification> _shellNotifications() {
    return [
      for (var i = 0; i < _notifications.length; i++)
        ShellNotification(
          id: 'n-$i',
          title: _notifications[i].title,
          body: _notifications[i].detail,
          icon: _notifications[i].icon,
          color: _notifications[i].color,
          time: _notifications[i].time,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final grades =
        List<Map<String, dynamic>>.from(_dashboard['grades'] as List? ?? []);
    final attendancePercent = asInt(_dashboard['attendancePercent'], 94);
    final gradeAverage = asInt(_dashboard['gradeAverage'], 86);
    final childName = _dashboard['childName']?.toString() ?? 'Aarav Sharma';

    return AppShell(
      title: 'Parent Portal',
      navItems: ShellNavConfig.parent,
      selectedIndex: _selectedNav,
      onNavSelected: (i) => setState(() => _selectedNav = i),
      sectionKeys: _sectionKeys,
      notifications: _shellNotifications(),
      onLogout: _logout,
      onRefresh: _refreshDashboard,
      isLoading: _loading,
      quickActions: [
        ShellQuickAction(
          label: 'Upload fee proof',
          icon: Icons.upload_file_outlined,
          onTap: _uploadFeeProof,
        ),
        ShellQuickAction(
          label: 'Refresh grades',
          icon: Icons.school_outlined,
          onTap: _loadGrades,
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
                  title: childName,
                  subtitle:
                      'Attendance, grades, reminders, and secure school communication.',
                  trailing: AppButton(
                    label: 'Refresh',
                    icon: Icons.refresh,
                    onPressed: _refreshDashboard,
                    size: AppButtonSize.sm,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardGrid(
                  children: [
                    KPIStatCard(
                      label: 'Child attendance',
                      value: '$attendancePercent%',
                      icon: Icons.how_to_reg_outlined,
                      color: colorScheme.primary,
                      trend: '+3%',
                      detail: 'Present today at 8:04 AM',
                      isLoading: _loading,
                    ),
                    KPIStatCard(
                      label: 'Grade average',
                      value: '$gradeAverage%',
                      icon: Icons.school_outlined,
                      color: Colors.teal,
                      trend: '+5%',
                      detail: 'Term 2 performance',
                      isLoading: _loading,
                    ),
                    KPIStatCard(
                      label: 'Fee reminders',
                      value: '${_dashboard['feeReminders'] ?? 1}',
                      icon: Icons.currency_rupee,
                      color: Colors.deepOrange,
                      detail: 'Transport fee due Friday',
                      isLoading: _loading,
                    ),
                    KPIStatCard(
                      label: 'Notifications',
                      value: '${_notifications.length}',
                      icon: Icons.notifications_none,
                      color: Colors.indigo,
                      detail: 'Latest school updates',
                      isLoading: _loading,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                DashboardSection(
                  title: 'Fee payment',
                  useGlassPanel: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload payment receipt so the teacher can verify it.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Upload fee proof',
                        icon: Icons.upload_file_outlined,
                        onPressed: _uploadFeeProof,
                        size: AppButtonSize.sm,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardSection(
                  title: 'AI progress summary',
                  useGlassPanel: false,
                  animate: false,
                  child: IntelligentInsightsPanel(
                    audience: 'parent',
                    primaryScore: attendancePercent,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const DashboardSection(
                  title: 'Family dashboard layout',
                  useGlassPanel: false,
                  animate: false,
                  child: PersonalizableDashboardStrip(
                    items: [
                      DashboardWidgetItem(
                        id: 'weekly-summary',
                        title: 'Weekly learning summary',
                        subtitle:
                            'Attendance, grades, homework, and suggestions.',
                        icon: Icons.auto_stories_outlined,
                        color: Colors.indigo,
                      ),
                      DashboardWidgetItem(
                        id: 'attendance-score',
                        title: 'Consistency score',
                        subtitle: 'Arrival regularity and absence prediction.',
                        icon: Icons.verified_user_outlined,
                        color: Colors.teal,
                      ),
                      DashboardWidgetItem(
                        id: 'improvements',
                        title: 'Improvement suggestions',
                        subtitle: 'Small daily actions recommended locally.',
                        icon: Icons.tips_and_updates_outlined,
                        color: Colors.deepOrange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['attendance']!,
            child: DashboardSection(
              title: 'Attendance progress',
              useGlassPanel: false,
              animate: false,
              child: ParentAttendanceModule(
                childName: childName,
                attendancePercent: attendancePercent,
                notifications: [
                  for (final n in _notifications)
                    AttendanceActivityItem(
                      title: n.title,
                      subtitle: n.detail,
                      timestamp: DateTime.now(),
                      status: n.color == Colors.teal
                          ? AttendanceStatus.present
                          : AttendanceStatus.unmarked,
                      icon: n.icon,
                    ),
                ],
                onRefresh: _refreshDashboard,
              ),
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['grades']!,
            child: DashboardSection(
              title: loc.grades,
              action: AppButton(
                label: 'Update',
                icon: Icons.refresh,
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: _loadGrades,
              ),
              useGlassPanel: false,
              child: Column(
                children: [
                  if (grades.isEmpty)
                    ProgressRow(
                      label: 'Mathematics',
                      value: '91%',
                      percent: 0.91,
                      color: colorScheme.primary,
                    )
                  else
                    for (var i = 0; i < grades.length; i++)
                      ProgressRow(
                        label: grades[i]['subject']?.toString() ?? 'Subject',
                        value: '${(_gradePercent(grades[i]) * 100).round()}%',
                        percent: _gradePercent(grades[i]),
                        color: [
                          colorScheme.primary,
                          Colors.teal,
                          Colors.indigo,
                          Colors.deepOrange,
                        ][i % 4],
                      ),
                ],
              ),
            ),
          ),
          ShellSection(
            sectionKey: GlobalKey(),
            child: const DashboardSection(
              title: 'Progress trends',
              useGlassPanel: false,
              animate: false,
              child: PremiumAnalyticsPanel(
                title: 'Attendance and grade trajectory',
                values: [78, 81, 86, 84, 89, 91, 94],
              ),
            ),
          ),
          ShellSection(
            sectionKey: GlobalKey(),
            child: const DashboardSection(
              title: 'Media gallery',
              useGlassPanel: false,
              animate: false,
              child: MediaExperiencePanel(),
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['homework']!,
            child: DashboardSection(
              title: loc.homework,
              useGlassPanel: false,
              animate: false,
              child: const ParentCommunicationModule(initialTab: 1),
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['messages']!,
            child: DashboardSection(
              title: 'Notices & ${loc.chat}',
              useGlassPanel: false,
              animate: false,
              child: const ParentCommunicationModule(initialTab: 2),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
