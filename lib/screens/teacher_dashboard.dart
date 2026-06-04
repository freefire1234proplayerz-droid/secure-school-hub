import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/dashboard/dashboard_components.dart';
import '../widgets/language_toggle.dart';
import 'login_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  static const routeName = '/teacher';

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final ApiService _api = ApiService();
  final TextEditingController _messageController = TextEditingController();
  bool _scanning = false;
  String _status = 'Ready for today';
  List<Map<String, dynamic>> _students = [];
  List<String> _chatMessages = [];
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

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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

  String _shortTime(String? raw) {
    if (raw == null) return 'Now';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 'Now';
    final local = parsed.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadChat() async {
    try {
      final res = await _api.get('/chat/history');
      final rows = List<Map<String, dynamic>>.from(
        res.data['messages'] as List<dynamic>? ?? [],
      );
      if (!mounted) return;
      setState(() {
        _chatMessages = rows
            .map((m) {
              final who = m['senderRole'] == 'teacher' ? 'Me' : 'Parent';
              return '$who: ${m['body']}';
            })
            .toList();
      });
    } catch (_) {
      // Chat stays empty until backend is reachable.
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadAttendanceDemo(), _loadChat()]);
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
    setState(() => _status = 'Marking attendance...');
    try {
      final res = await _api.post('/attendance/mark', data: {'qr': qrData});
      final student = res.data['student'] as Map<String, dynamic>?;
      final status = res.data['status']?.toString() == 'already_marked'
          ? 'already marked present'
          : 'marked present';
      setState(() {
        _status = student == null
            ? 'Attendance marked'
            : '${student['name']} $status. Parent notification triggered.';
      });
      await _refreshAll();
    } catch (e) {
      setState(() => _status = 'Attendance failed: ${_formatError(e)}');
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
      _showSnack('Failed: ${_formatError(e)}', isError: true);
    }
  }

  Future<void> _takeAttendancePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance photo captured.')),
    );
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
    setState(() => _status = 'Requesting infrastructure health check...');
    try {
      final res = await _api.post('/security/scan', data: {'target': '127.0.0.1'});
      final result = res.data['result']?.toString() ??
          res.data['status']?.toString() ??
          'Health check complete';
      setState(() => _status = result);
      if (!mounted) return;
      _showSnack('Infrastructure health check completed.');
    } catch (e) {
      setState(() => _status = 'Health check failed: ${_formatError(e)}');
      if (!mounted) return;
      _showSnack('Health check failed: ${_formatError(e)}', isError: true);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add('Me: $text');
      _messageController.clear();
    });

    try {
      await _api.post('/chat/send', data: {'message': text});
      await _loadChat();
      await _loadAttendanceDemo();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Send failed: ${_formatError(e)}', isError: true);
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

    return Focus(
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.teacher),
          actions: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: LanguageToggle()),
            ),
            IconButton(
              tooltip: 'Logout',
              onPressed: _logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: DashboardShell(
          title: 'Class 8A Command Center',
          subtitle:
              'QR attendance, homework, reminders, and class health in one workspace.',
          trailing: FilledButton.icon(
            onPressed: () => setState(() => _scanning = true),
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(loc.scanQr),
          ),
          children: [
            ResponsiveGrid(
              children: [
                MetricCard(
                  label: 'Students present',
                  value: '$presentToday / $totalStudents',
                  icon: Icons.groups_2_outlined,
                  color: colorScheme.primary,
                  trend: '+4%',
                  detail: 'Morning session synced',
                ),
                const MetricCard(
                  label: 'Attendance',
                  value: '90.4%',
                  icon: Icons.fact_check_outlined,
                  color: Colors.teal,
                  trend: '+2.1%',
                  detail: 'Weekly average',
                ),
                MetricCard(
                  label: 'Live QR attendance',
                  value: '$attendancePercent%',
                  icon: Icons.qr_code_scanner,
                  color: Colors.green,
                  detail: 'From today\'s QR marks',
                ),
                MetricCard(
                  label: 'Homework sent',
                  value: '${_dashboard['homeworkSent'] ?? 3}',
                  icon: Icons.assignment_outlined,
                  color: Colors.deepOrange,
                  detail: '2 checked, 1 due tomorrow',
                ),
                MetricCard(
                  label: 'Parent alerts',
                  value: '${_dashboard['parentAlerts'] ?? 7}',
                  icon: Icons.notifications_active_outlined,
                  color: Colors.indigo,
                  detail: 'Auto alerts ready',
                ),
              ],
            ),
            const SizedBox(height: 18),
            DashboardSection(
              title: loc.attendance,
              child: DashboardPanel(
                child: _scanning
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Scan student QR',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close scanner',
                                onPressed: () =>
                                    setState(() => _scanning = false),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 260,
                              child: MobileScanner(
                                onDetect: (capture) {
                                  final barcode = capture.barcodes.firstOrNull;
                                  if (barcode?.rawValue != null) {
                                    setState(() => _scanning = false);
                                    _markAttendance(barcode!.rawValue!);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AttendanceLineChart(
                            values: [88, 91, 86, 93, 90, 95],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: () =>
                                    setState(() => _scanning = true),
                                icon: const Icon(Icons.qr_code_scanner),
                                label: Text(loc.scanQr),
                              ),
                              OutlinedButton.icon(
                                onPressed: _takeAttendancePhoto,
                                icon: const Icon(Icons.camera_alt_outlined),
                                label: const Text('Class photo'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _status,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
              ),
            ),
            DashboardSection(
              title: 'Student QR codes',
              action: TextButton.icon(
                onPressed: _loadAttendanceDemo,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              child: _students.isEmpty
                  ? const DashboardPanel(
                      child: Text(
                        'Login as teacher to load demo student QR codes.',
                      ),
                    )
                  : ResponsiveGrid(
                      minItemWidth: 250,
                      children: [
                        for (final student in _students)
                          DashboardPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: QrImageView(
                                        data:
                                            student['qrPayload']?.toString() ??
                                                student['qrCode'].toString(),
                                        size: 86,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
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
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () => _markAttendance(
                                    student['qrPayload'].toString(),
                                  ),
                                  icon: const Icon(Icons.how_to_reg_outlined),
                                  label: const Text('Mark present'),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            DashboardSection(
              title: 'Quick actions',
              child: ResponsiveGrid(
                minItemWidth: 260,
                children: [
                  ActionTile(
                    label: 'Assign homework',
                    description: 'Send task and queue offline sync',
                    icon: Icons.post_add_outlined,
                    onTap: _createHomework,
                  ),
                  ActionTile(
                    label: 'Attach homework file',
                    description: 'Upload worksheet, PDF, or image',
                    icon: Icons.attach_file,
                    onTap: _attachHomeworkFile,
                  ),
                  ActionTile(
                    label: 'Send fee reminder',
                    description: 'Trigger payment reminder workflow',
                    icon: Icons.currency_rupee,
                    onTap: _sendFeeReminder,
                  ),
                  ActionTile(
                    label: 'Infrastructure health',
                    description: 'Basic server-side health monitoring',
                    icon: Icons.health_and_safety_outlined,
                    onTap: _runInfrastructureCheck,
                  ),
                  ActionTile(
                    label: 'Upload fee proof',
                    description: 'Attach receipt or payment evidence',
                    icon: Icons.receipt_long_outlined,
                    onTap: _attachFeeFile,
                  ),
                ],
              ),
            ),
            DashboardSection(
              title: 'Class stats',
              child: DashboardPanel(
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
                      percent: (((classOverview['feeFollowupClosed'] as num?) ??
                                  68) /
                              100)
                          .clamp(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            DashboardSection(
              title: 'Parent updates',
              action: TextButton.icon(
                onPressed: _refreshAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              child: DashboardPanel(
                child: NotificationList(
                  items: _feedNotifications.isEmpty
                      ? const [
                          DashboardNotification(
                            title: 'Waiting for parent activity',
                            detail:
                                'Messages, fee proofs, and attendance alerts appear here.',
                            icon: Icons.inbox_outlined,
                            color: Colors.blueGrey,
                            time: 'Now',
                          ),
                        ]
                      : _feedNotifications,
                ),
              ),
            ),
            DashboardSection(
              title: 'Parent chat',
              child: DashboardPanel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Encrypted parent-teacher messaging',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh chat',
                            onPressed: _loadChat,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _chatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = _chatMessages[index];
                          final isMe = msg.startsWith('Me:');
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 320),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                vertical: 9,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(msg),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Message parents',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: 'Send message',
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
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
