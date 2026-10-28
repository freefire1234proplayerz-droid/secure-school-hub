import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/glass_card.dart';
import '../widgets/attendance/teacher_attendance_module.dart';
import '../widgets/communication/teacher_communication_module.dart';
import '../widgets/shell/app_shell.dart';
import '../widgets/dashboard/dashboard_components.dart';
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
    'totalStudents': 0,
    'presentToday': 0,
    'attendancePercent': 0,
  };
  Map<String, dynamic> _dashboard = {
    'homeworkSent': 0,
    'parentAlerts': 0,
    'classOverview': {
      'homeworkCompletion': 0,
      'feeFollowupClosed': 0,
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
        return 'Server endpoint missing. Restart backend.';
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
          title: 'Waiting for activity',
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
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to load data: ${_formatError(e)}', isError: true);
      setState(() => _loading = false);
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
            : '${student['name']} $status. Parent notified.',
      );
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
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
      _showSnack('Homework assigned — parents notified.');
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
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
    final totalStudents = _attendanceSummary['totalStudents'] ?? 0;
    final presentToday = _attendanceSummary['presentToday'] ?? 0;
    final attendancePercent = _attendanceSummary['attendancePercent'] ?? 0;
    final classOverview =
        Map<String, dynamic>.from(_dashboard['classOverview'] as Map? ?? {});

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
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(loc),
                    const SizedBox(height: 24),
                    _buildKpiCards(colorScheme, totalStudents, presentToday, attendancePercent),
                    const SizedBox(height: 24),
                    _buildClassStats(classOverview, attendancePercent),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  key: _sectionKeys['attendance']!,
                  title: "Today's classes — ${loc.attendance}",
                  child: TeacherAttendanceModule(key: _attendanceModuleKey),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  key: _sectionKeys['students']!,
                  title: 'Student quick access',
                  action: AppButton(
                    label: 'Refresh',
                    icon: Icons.refresh,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.sm,
                    onPressed: _refreshAll,
                  ),
                  child: _students.isEmpty
                      ? _EmptyState(
                          icon: Icons.groups_2_outlined,
                          title: 'No students loaded',
                          message:
                              'Sign in as teacher to load student QR codes.',
                        )
                      : _StudentGrid(
                          students: _students,
                          onMarkAttendance: _markAttendance,
                        ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: _buildSection(
                  key: _sectionKeys['actions']!,
                  title: 'Quick actions',
                  child: _QuickActionsGrid(
                    onCreateHomework: _createHomework,
                    onAttachHomeworkFile: _attachHomeworkFile,
                    onSendFeeReminder: _sendFeeReminder,
                    onRunInfrastructureCheck: _runInfrastructureCheck,
                    onAttachFeeFile: _attachFeeFile,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  key: _sectionKeys['messages']!,
                  title: 'Notices & communication',
                  child: TeacherCommunicationModule(key: _communicationModuleKey),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class 8A Command Center',
                style: AppTextStyles.pageTitle(Theme.of(context).textTheme),
              ),
              const SizedBox(height: 4),
              Text(
                'QR attendance, homework, reminders, and class health in one workspace.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        AppButton(
          label: loc.scanQr,
          icon: Icons.qr_code_scanner,
          onPressed: () => _attendanceModuleKey.currentState?.openQrScanner(),
          size: AppButtonSize.sm,
        ),
      ],
    );
  }

  Widget _buildKpiCards(ColorScheme colorScheme, int totalStudents, int presentToday, int attendancePercent) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _KpiCard(
          label: 'Students present',
          value: '$presentToday / $totalStudents',
          icon: Icons.groups_2_outlined,
          color: colorScheme.primary,
          detail: 'Morning session synced',
          isLoading: _loading,
        ),
        _KpiCard(
          label: 'Attendance rate',
          value: '$attendancePercent%',
          icon: Icons.fact_check_outlined,
          color: Colors.teal,
          detail: 'From today\'s QR marks',
          isLoading: _loading,
        ),
        _KpiCard(
          label: 'Homework sent',
          value: '${_dashboard['homeworkSent'] ?? 0}',
          icon: Icons.assignment_outlined,
          color: Colors.deepOrange,
          detail: 'Active assignments',
          isLoading: _loading,
        ),
        _KpiCard(
          label: 'Parent alerts',
          value: '${_dashboard['parentAlerts'] ?? 0}',
          icon: Icons.notifications_active_outlined,
          color: Colors.indigo,
          detail: 'Auto alerts active',
          isLoading: _loading,
        ),
      ],
    );
  }

  Widget _buildClassStats(Map<String, dynamic> classOverview, int attendancePercent) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ProgressRow(
            label: 'Class 8A attendance',
            value: '$attendancePercent%',
            percent: (attendancePercent / 100).clamp(0, 1),
          ),
          _ProgressRow(
            label: 'Homework completion',
            value:
                '${(classOverview['homeworkCompletion'] as num? ?? 0)}%',
            percent:
                (((classOverview['homeworkCompletion'] as num?) ?? 0) / 100)
                    .clamp(0, 1),
          ),
          _ProgressRow(
            label: 'Fee follow-up closed',
            value:
                '${(classOverview['feeFollowupClosed'] as num? ?? 0)}%',
            percent:
                (((classOverview['feeFollowupClosed'] as num?) ?? 0) / 100)
                    .clamp(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
              label: 'Assign homework',
              description: 'Send task to students and parents',
              icon: Icons.post_add_outlined,
              onTap: _createHomework,
            ),
            _ActionCard(
              label: 'Attach homework file',
              description: 'Upload worksheet, PDF, or image',
              icon: Icons.attach_file,
              onTap: _attachHomeworkFile,
            ),
            _ActionCard(
              label: 'Send fee reminder',
              description: 'Trigger payment reminder workflow',
              icon: Icons.currency_rupee,
              onTap: _sendFeeReminder,
            ),
            _ActionCard(
              label: 'Infrastructure health',
              description: 'Basic server-side health monitoring',
              icon: Icons.health_and_safety_outlined,
              onTap: _runInfrastructureCheck,
            ),
            _ActionCard(
              label: 'Upload fee proof',
              description: 'Attach receipt or payment evidence',
              icon: Icons.receipt_long_outlined,
              onTap: _attachFeeFile,
            ),
          ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StudentGrid extends StatelessWidget {
  const _StudentGrid({
    required this.students,
    required this.onMarkAttendance,
  });

  final List<Map<String, dynamic>> students;
  final void Function(String) onMarkAttendance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final student in students)
          _StudentCard(
            student: student,
            onMarkAttendance: onMarkAttendance,
          ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.onMarkAttendance,
  });

  final Map<String, dynamic> student;
  final void Function(String) onMarkAttendance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 250, maxWidth: 300),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: student['qrPayload']?.toString() ??
                        student['qrCode'].toString(),
                    size: 72,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'].toString(),
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${student['className']} • Roll ${student['rollNo']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Mark present',
              icon: Icons.how_to_reg_outlined,
              onPressed: () => onMarkAttendance(
                student['qrPayload'].toString(),
              ),
              size: AppButtonSize.sm,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onCreateHomework,
    required this.onAttachHomeworkFile,
    required this.onSendFeeReminder,
    required this.onRunInfrastructureCheck,
    required this.onAttachFeeFile,
  });

  final VoidCallback onCreateHomework;
  final VoidCallback onAttachHomeworkFile;
  final VoidCallback onSendFeeReminder;
  final VoidCallback onRunInfrastructureCheck;
  final VoidCallback onAttachFeeFile;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionCard(
          label: 'Assign homework',
          description: 'Send task to students and parents',
          icon: Icons.post_add_outlined,
          onTap: onCreateHomework,
        ),
        _ActionCard(
          label: 'Attach homework file',
          description: 'Upload worksheet, PDF, or image',
          icon: Icons.attach_file,
          onTap: onAttachHomeworkFile,
        ),
        _ActionCard(
          label: 'Send fee reminder',
          description: 'Trigger payment reminder workflow',
          icon: Icons.currency_rupee,
          onTap: onSendFeeReminder,
        ),
        _ActionCard(
          label: 'Infrastructure health',
          description: 'Basic server-side health monitoring',
          icon: Icons.health_and_safety_outlined,
          onTap: onRunInfrastructureCheck,
        ),
        _ActionCard(
          label: 'Upload fee proof',
          description: 'Attach receipt or payment evidence',
          icon: Icons.receipt_long_outlined,
          onTap: onAttachFeeFile,
        ),
      ],
    );
  }
}