import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/frontend_experience_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/dashboard/dashboard_components.dart' hide DashboardSection;
import '../widgets/dashboard/dashboard_grid.dart';
import '../widgets/dashboard/dashboard_section.dart';
import '../widgets/dashboard/empty_state.dart';
import '../widgets/dashboard/kpi_stat_card.dart';
import '../widgets/dashboard/quick_action_card.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/glass_card.dart';
import '../widgets/attendance/teacher_attendance_module.dart';
import '../widgets/communication/teacher_communication_module.dart';
import '../widgets/experience/production_experience.dart';
import '../widgets/shell/app_shell.dart';
import 'login_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  static const routeName = '/teacher';

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final ApiService _api = ApiService();
  bool _loading = true;
  final _attendanceModuleKey = GlobalKey<TeacherAttendanceModuleState>();
  final _communicationModuleKey = GlobalKey<TeacherCommunicationModuleState>();
  int _selectedNav = 0;
  List<Map<String, dynamic>> _students = [];
  List<DashboardNotification> _feedNotifications = [];
  Map<String, dynamic> _attendanceSummary = {
    'totalStudents': 42,
    'presentToday': 38,
    'attendancePercent': 90,
  };
  Map<String, dynamic> _dashboard = {
    'homeworkSent': 3,
    'parentAlerts': 7,
    'classOverview': {
      'homeworkCompletion': 76,
      'feeFollowupClosed': 68,
    },
  };

  final _sectionKeys = <String, GlobalKey>{
    for (final id in [
      'overview',
      'attendance',
      'students',
      'actions',
      'messages',
    ])
      id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  String _formatError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
      if (e.response?.statusCode == 404) {
        return 'Server endpoint missing. Restart backend: docker compose restart server';
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

  List<DashboardNotification> _mapNotifications(List<dynamic> rows) {
    return rows.map((row) {
      final map = Map<String, dynamic>.from(row as Map);
      final type = map['type']?.toString();
      return DashboardNotification(
        title: map['title']?.toString() ?? 'Update',
        detail: map['body']?.toString() ?? '',
        icon: type == 'chat'
            ? Icons.chat_bubble_outline
            : type == 'fee'
                ? Icons.receipt_long_outlined
                : type == 'homework'
                    ? Icons.assignment_outlined
                    : Icons.notifications_none,
        color: type == 'chat'
            ? Colors.indigo
            : type == 'fee'
                ? Colors.deepOrange
                : type == 'homework'
                    ? Colors.teal
                    : Colors.blueGrey,
        time: _shortTime(map['created_at']?.toString()),
      );
    }).toList();
  }

  List<ShellNotification> _shellNotifications() {
    if (_feedNotifications.isEmpty) {
      return const [
        ShellNotification(
          id: 'inbox',
          title: 'Waiting for parent activity',
          body: 'Messages, fee proofs, and attendance alerts appear here.',
          icon: Icons.inbox_outlined,
          color: Colors.blueGrey,
          time: 'Now',
        ),
      ];
    }
    return [
      for (var i = 0; i < _feedNotifications.length; i++)
        ShellNotification(
          id: 'feed-$i',
          title: _feedNotifications[i].title,
          body: _feedNotifications[i].detail,
          icon: _feedNotifications[i].icon,
          color: _feedNotifications[i].color,
          time: _feedNotifications[i].time,
        ),
    ];
  }

  String _shortTime(String? raw) {
    if (raw == null) return 'Now';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 'Now';
    final local = parsed.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshAll() async {
    setState(() => _loading = true);
    await _loadAttendanceDemo();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadAttendanceDemo() async {
    try {
      final studentsRes = await _api.get('/attendance/students');
      final summaryRes = await _api.get('/attendance/summary');
      final dashboardRes = await _api.get('/dashboard/teacher');
      if (!mounted) return;
      final dashboard = Map<String, dynamic>.from(dashboardRes.data as Map);
      final notificationRows =
          dashboard['notifications'] as List<dynamic>? ?? [];
      setState(() {
        _students = List<Map<String, dynamic>>.from(
          studentsRes.data['students'] as List<dynamic>,
        );
        _attendanceSummary = Map<String, dynamic>.from(summaryRes.data as Map);
        _dashboard = dashboard;
        _feedNotifications = _mapNotifications(notificationRows);
      });
    } catch (_) {
      // Keep the static premium dashboard usable if the demo API is offline.
    }
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _markAttendance(String qrData) async {
    try {
      final res = await _api.post('/attendance/mark', data: {'qr': qrData});
      final student = res.data['student'] as Map<String, dynamic>?;
      final status = res.data['status']?.toString() == 'already_marked'
          ? 'already marked present'
          : 'marked present';
      if (!mounted) return;
      _showSnack(
        student == null
            ? 'Attendance marked'
            : '${student['name']} $status. Parent notification triggered.',
      );
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      await FrontendExperienceService.instance.queueAction(
        PendingActionType.attendance,
        title: 'Offline attendance mark',
        payload: {'qr': qrData},
      );
      _showSnack('Attendance failed: ${_formatError(e)}', isError: true);
    }
  }

  Future<void> _createHomework() async {
    try {
      await _api.post('/homework/create', data: {
        'title': 'Math practice',
        'description': 'Solve exercise 5 from chapter 2',
      });
      if (!mounted) return;
      _showSnack('Homework assigned — parents will see it instantly.');
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      await FrontendExperienceService.instance.queueAction(
        PendingActionType.noticeDraft,
        title: 'Offline homework draft',
        payload: const {
          'title': 'Math practice',
          'description': 'Solve exercise 5 from chapter 2',
        },
      );
      _showSnack('Failed: ${_formatError(e)}', isError: true);
    }
  }

  Future<void> _attachHomeworkFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    try {
      await _api.post('/homework/attach', data: {
        'fileName': file.name,
        'size': file.size,
        'title': 'Class 8A worksheet',
      });
      if (!mounted) return;
      _showSnack('Attached ${file.name} — shared with parents.');
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      await FrontendExperienceService.instance.queueAction(
        PendingActionType.upload,
        title: 'Offline homework attachment: ${file.name}',
        payload: {'fileName': file.name, 'size': file.size},
      );
      _showSnack('Attach failed: ${_formatError(e)}', isError: true);
    }
  }

  Future<void> _attachFeeFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    try {
      await _api.post('/fees/attach', data: {
        'fileName': file.name,
        'size': file.size,
      });
      if (!mounted) return;
      _showSnack('Fee document ${file.name} shared with parents.');
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      await FrontendExperienceService.instance.queueAction(
        PendingActionType.upload,
        title: 'Offline fee attachment: ${file.name}',
        payload: {'fileName': file.name, 'size': file.size},
      );
      _showSnack('Attach failed: ${_formatError(e)}', isError: true);
    }
  }

  Future<void> _sendFeeReminder() async {
    try {
      await _api.post('/fees/remind', data: {
        'amount': 5000,
        'currency': 'INR',
      });
      if (!mounted) return;
      _showSnack('Fee reminder sent to all parents.');
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      await FrontendExperienceService.instance.queueAction(
        PendingActionType.noticeDraft,
        title: 'Offline fee reminder',
        payload: const {'amount': 5000, 'currency': 'INR'},
      );
      _showSnack('Failed: ${_formatError(e)}', isError: true);
    }
  }

  Future<void> _runInfrastructureCheck() async {
    try {
      await _api.post('/security/scan', data: {'target': '127.0.0.1'});
      if (!mounted) return;
      _showSnack('Infrastructure health check completed.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Health check failed: ${_formatError(e)}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final totalStudents = _attendanceSummary['totalStudents'] ?? 42;
    final presentToday = _attendanceSummary['presentToday'] ?? 38;
    final attendancePercent = _attendanceSummary['attendancePercent'] ?? 90;
    final classOverview =
        Map<String, dynamic>.from(_dashboard['classOverview'] as Map);

    return AppShell(
      title: 'Teacher Workspace',
      navItems: ShellNavConfig.teacher,
      selectedIndex: _selectedNav,
      onNavSelected: (i) => setState(() => _selectedNav = i),
      sectionKeys: _sectionKeys,
      notifications: _shellNotifications(),
      onLogout: _logout,
      onRefresh: _refreshAll,
      isLoading: _loading,
      quickActions: [
        ShellQuickAction(
          label: loc.scanQr,
          icon: Icons.qr_code_scanner,
          onTap: () => _attendanceModuleKey.currentState?.openQrScanner(),
        ),
        ShellQuickAction(
          label: 'Assign homework',
          icon: Icons.post_add_outlined,
          onTap: _createHomework,
        ),
        ShellQuickAction(
          label: 'Fee reminder',
          icon: Icons.currency_rupee,
          onTap: _sendFeeReminder,
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
                  title: 'Class 8A Command Center',
                  subtitle:
                      'QR attendance, homework, reminders, and class health in one workspace.',
                  trailing: AppButton(
                    label: loc.scanQr,
                    icon: Icons.qr_code_scanner,
                    onPressed: () =>
                        _attendanceModuleKey.currentState?.openQrScanner(),
                    size: AppButtonSize.sm,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardGrid(
                  children: [
                    KPIStatCard(
                      label: 'Students present',
                      value: '$presentToday / $totalStudents',
                      icon: Icons.groups_2_outlined,
                      color: colorScheme.primary,
                      trend: '+4%',
                      detail: 'Morning session synced',
                      isLoading: _loading,
                    ),
                    const KPIStatCard(
                      label: 'Attendance',
                      value: '90.4%',
                      icon: Icons.fact_check_outlined,
                      color: Colors.teal,
                      trend: '+2.1%',
                      detail: 'Weekly average',
                    ),
                    KPIStatCard(
                      label: 'Live QR attendance',
                      value: '$attendancePercent%',
                      icon: Icons.qr_code_scanner,
                      color: Colors.green,
                      detail: 'From today\'s QR marks',
                      isLoading: _loading,
                    ),
                    KPIStatCard(
                      label: 'Homework sent',
                      value: '${_dashboard['homeworkSent'] ?? 3}',
                      icon: Icons.assignment_outlined,
                      color: Colors.deepOrange,
                      detail: '2 checked, 1 due tomorrow',
                      isLoading: _loading,
                    ),
                    KPIStatCard(
                      label: 'Parent alerts',
                      value: '${_dashboard['parentAlerts'] ?? 7}',
                      icon: Icons.notifications_active_outlined,
                      color: Colors.indigo,
                      detail: 'Auto alerts ready',
                      isLoading: _loading,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardSection(
                  title: 'Class stats',
                  useGlassPanel: false,
                  animate: false,
                  child: Column(
                    children: [
                      ProgressRow(
                        label: 'Class 8A attendance',
                        value: '$attendancePercent%',
                        percent: (attendancePercent / 100).clamp(0, 1),
                      ),
                      ProgressRow(
                        label: 'Homework completion',
                        value: '${classOverview['homeworkCompletion'] ?? 76}%',
                        percent:
                            (((classOverview['homeworkCompletion'] as num?) ??
                                        76) /
                                    100)
                                .clamp(0, 1),
                      ),
                      ProgressRow(
                        label: 'Fee follow-up closed',
                        value: '${classOverview['feeFollowupClosed'] ?? 68}%',
                        percent:
                            (((classOverview['feeFollowupClosed'] as num?) ??
                                        68) /
                                    100)
                                .clamp(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardSection(
                  title: 'AI class insights',
                  useGlassPanel: false,
                  animate: false,
                  child: IntelligentInsightsPanel(
                    audience: 'teacher',
                    primaryScore: (attendancePercent as num).toInt(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const DashboardSection(
                  title: 'Personalized workspace',
                  useGlassPanel: false,
                  animate: false,
                  child: PersonalizableDashboardStrip(
                    items: [
                      DashboardWidgetItem(
                        id: 'risk',
                        title: 'Attendance risk watchlist',
                        subtitle: 'Pinned students with two missed mornings.',
                        icon: Icons.warning_amber_outlined,
                        color: Colors.deepOrange,
                      ),
                      DashboardWidgetItem(
                        id: 'engagement',
                        title: 'Class engagement',
                        subtitle: 'Live opens, replies, and homework activity.',
                        icon: Icons.forum_outlined,
                        color: Colors.teal,
                      ),
                      DashboardWidgetItem(
                        id: 'homework',
                        title: 'Homework completion',
                        subtitle: 'Trend comparison by subject.',
                        icon: Icons.assignment_turned_in_outlined,
                        color: Colors.indigo,
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
              title: "Today's classes — ${loc.attendance}",
              useGlassPanel: false,
              animate: false,
              child: TeacherAttendanceModule(key: _attendanceModuleKey),
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['students']!,
            child: DashboardSection(
              title: 'Student quick access',
              action: AppButton(
                label: 'Refresh',
                icon: Icons.refresh,
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: _loadAttendanceDemo,
              ),
              useGlassPanel: false,
              child: _students.isEmpty
                  ? const DashboardEmptyState(
                      icon: Icons.groups_2_outlined,
                      title: 'No students loaded',
                      message:
                          'Login as teacher to load demo student QR codes.',
                      compact: true,
                    )
                  : DashboardGrid(
                      minItemWidth: 250,
                      children: [
                        for (final student in _students)
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.xs,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: AppSpacing.borderRadiusSm,
                                      ),
                                      child: QrImageView(
                                        data:
                                            student['qrPayload']?.toString() ??
                                                student['qrCode'].toString(),
                                        size: 86,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['name'].toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${student['className']} • Roll ${student['rollNo']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppButton(
                                  label: 'Mark present',
                                  icon: Icons.how_to_reg_outlined,
                                  onPressed: () => _markAttendance(
                                    student['qrPayload'].toString(),
                                  ),
                                  size: AppButtonSize.sm,
                                  expand: true,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['actions']!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardSection(
                  title: 'Quick actions',
                  useGlassPanel: false,
                  child: DashboardGrid(
                    minItemWidth: 260,
                    children: [
                      QuickActionCard(
                        label: 'Assign homework',
                        description: 'Send task and queue offline sync',
                        icon: Icons.post_add_outlined,
                        onTap: _createHomework,
                      ),
                      QuickActionCard(
                        label: 'Attach homework file',
                        description: 'Upload worksheet, PDF, or image',
                        icon: Icons.attach_file,
                        onTap: _attachHomeworkFile,
                      ),
                      QuickActionCard(
                        label: 'Send fee reminder',
                        description: 'Trigger payment reminder workflow',
                        icon: Icons.currency_rupee,
                        onTap: _sendFeeReminder,
                      ),
                      QuickActionCard(
                        label: 'Infrastructure health',
                        description: 'Basic server-side health monitoring',
                        icon: Icons.health_and_safety_outlined,
                        onTap: _runInfrastructureCheck,
                      ),
                      QuickActionCard(
                        label: 'Upload fee proof',
                        description: 'Attach receipt or payment evidence',
                        icon: Icons.receipt_long_outlined,
                        onTap: _attachFeeFile,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const DashboardSection(
                  title: 'Files, exports & reports',
                  useGlassPanel: false,
                  animate: false,
                  child: MediaExperiencePanel(),
                ),
              ],
            ),
          ),
          ShellSection(
            sectionKey: GlobalKey(),
            child: const DashboardSection(
              title: 'Interactive analytics',
              useGlassPanel: false,
              animate: false,
              child: PremiumAnalyticsPanel(
                title: 'Attendance and homework momentum',
                values: [82, 86, 84, 90, 88, 93, 91],
              ),
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['messages']!,
            child: DashboardSection(
              title: 'Notices & communication',
              useGlassPanel: false,
              animate: false,
              child: TeacherCommunicationModule(key: _communicationModuleKey),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
