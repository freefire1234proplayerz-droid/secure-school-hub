import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_text_styles.dart';
import '../utils/json_num.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/glass_card.dart';
import '../widgets/attendance/attendance_models.dart';
import '../widgets/attendance/parent_attendance_module.dart';
import '../widgets/communication/parent_communication_module.dart';
import '../widgets/shell/app_shell.dart';
import '../widgets/dashboard/dashboard_components.dart';
import 'login_screen.dart';
import 'student/ai_tutor_screen.dart';

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
      'ai_tutor',
      'homework',
      'messages',
    ])
      id: GlobalKey(),
  };

  List<DashboardNotification> _notifications = [];
  Map<String, dynamic> _dashboard = {
    'childName': 'Aarav Sharma',
    'attendancePercent': 0,
    'gradeAverage': 0,
    'feeReminders': 0,
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
      _showSnack('Upload failed: ${_formatError(e)}', isError: true);
    }
  }

  void _openAiTutor() {
    Navigator.pushNamed(context, AiTutorScreen.routeName);
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
      // Keep empty if API not reachable
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
    if (_notifications.isEmpty) {
      return const [
        ShellNotification(
          id: 'inbox',
          title: 'No new notifications',
          body: 'School updates will appear here.',
          icon: Icons.inbox_outlined,
          color: Colors.blueGrey,
          time: 'Now',
        ),
      ];
    }
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
    final attendancePercent = asInt(_dashboard['attendancePercent'], 0);
    final gradeAverage = asInt(_dashboard['gradeAverage'], 0);
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
        ShellQuickAction(
          label: 'AI Study Buddy',
          icon: Icons.smart_toy_outlined,
          description: 'Ask doubts and get homework support',
          onTap: _openAiTutor,
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(childName),
                    const SizedBox(height: 24),
                    _buildKpiCards(colorScheme, attendancePercent, gradeAverage),
                    const SizedBox(height: 24),
                    _buildFeePaymentSection(),
                    const SizedBox(height: 24),
                    _buildLearningSupport(),
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
                  title: 'Attendance progress',
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
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  key: _sectionKeys['grades']!,
                  title: loc.grades,
                  action: AppButton(
                    label: 'Update',
                    icon: Icons.refresh,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.sm,
                    onPressed: _loadGrades,
                  ),
                  child: _buildGrades(grades, colorScheme),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: _buildSection(
                  key: _sectionKeys['ai_tutor']!,
                  title: 'AI Study Buddy',
                  child: _buildAiTutorSection(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  key: _sectionKeys['homework']!,
                  title: loc.homework,
                  child: const ParentCommunicationModule(initialTab: 1),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSection(
                  key: _sectionKeys['messages']!,
                  title: 'Notices & ${loc.chat}',
                  child: const ParentCommunicationModule(initialTab: 2),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String childName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                childName,
                style: AppTextStyles.pageTitle(Theme.of(context).textTheme),
              ),
              const SizedBox(height: 4),
              Text(
                'Attendance, grades, reminders, and secure school communication.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        AppButton(
          label: 'Refresh',
          icon: Icons.refresh,
          onPressed: _refreshDashboard,
          size: AppButtonSize.sm,
        ),
      ],
    );
  }

  Widget _buildKpiCards(ColorScheme colorScheme, int attendancePercent, int gradeAverage) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _KpiCard(
          label: 'Child attendance',
          value: '$attendancePercent%',
          icon: Icons.how_to_reg_outlined,
          color: colorScheme.primary,
          detail: attendancePercent > 0 ? 'Present today' : 'No data',
          isLoading: _loading,
        ),
        _KpiCard(
          label: 'Grade average',
          value: '$gradeAverage%',
          icon: Icons.school_outlined,
          color: Colors.teal,
          detail: gradeAverage > 0 ? 'Term performance' : 'No grades yet',
          isLoading: _loading,
        ),
        _KpiCard(
          label: 'Fee reminders',
          value: '${_dashboard['feeReminders'] ?? 0}',
          icon: Icons.currency_rupee,
          color: Colors.deepOrange,
          detail: 'Pending payments',
          isLoading: _loading,
        ),
        _KpiCard(
          label: 'Notifications',
          value: '${_notifications.length}',
          icon: Icons.notifications_none,
          color: Colors.indigo,
          detail: 'Latest school updates',
          isLoading: _loading,
        ),
      ],
    );
  }

  Widget _buildFeePaymentSection() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fee payment',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload payment receipt so the teacher can verify it.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Upload fee proof',
            icon: Icons.upload_file_outlined,
            onPressed: _uploadFeeProof,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
  }

  Widget _buildLearningSupport() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning support',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            label: 'AI Study Buddy',
            description: 'Ask doubts, learn concepts, solve homework, and get chapter explanations.',
            icon: Icons.smart_toy_outlined,
            color: Colors.indigo,
            onTap: _openAiTutor,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final prompt in const [
                'Explain Photosynthesis',
                'Teach Algebra',
                'Solve 2x + 5 = 15',
                'Explain Newton\'s Laws',
              ])
                ActionChip(
                  avatar: const Icon(Icons.lightbulb_outline, size: 18),
                  label: Text(prompt),
                  onPressed: _openAiTutor,
                ),
            ],
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
              label: 'Refresh grades',
              description: 'Fetch latest grades from school',
              icon: Icons.school_outlined,
              onTap: _loadGrades,
            ),
            _ActionCard(
              label: 'Upload fee proof',
              description: 'Send payment receipt to teacher',
              icon: Icons.upload_file_outlined,
              onTap: _uploadFeeProof,
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

  Widget _buildGrades(List<Map<String, dynamic>> grades, ColorScheme colorScheme) {
    if (grades.isEmpty) {
      return _EmptyState(
        icon: Icons.school_outlined,
        title: 'No grades available',
        message: 'Grades will appear here once published by the school.',
      );
    }

    return Column(
      children: [
        for (var i = 0; i < grades.length; i++)
          _ProgressRow(
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
    );
  }

  Widget _buildAiTutorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Help your child learn with AI-powered explanations and homework support.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Open AI Tutor',
          icon: Icons.smart_toy_outlined,
          onPressed: _openAiTutor,
          size: AppButtonSize.sm,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final prompt in const [
              'Explain Photosynthesis',
              'Teach Algebra',
              'Solve 2x + 5 = 15',
              'Explain Newton\'s Laws',
            ])
              ActionChip(
                avatar: const Icon(Icons.lightbulb_outline, size: 18),
                label: Text(prompt),
                onPressed: _openAiTutor,
              ),
          ],
        ),
      ],
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
    this.color,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actionColor = color ?? colorScheme.primary;

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
                Icon(icon, color: actionColor, size: 24),
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