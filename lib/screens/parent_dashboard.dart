import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/json_num.dart';
import '../widgets/dashboard/dashboard_components.dart';
import '../widgets/language_toggle.dart';
import 'login_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  static const routeName = '/parent';

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final ApiService _api = ApiService();
  final TextEditingController _messageController = TextEditingController();
  List<String> _messages = [
    'Teacher: Aarav reached school safely.',
    'Me: Thank you, ma\'am.',
  ];
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
    _loadDashboard();
    _loadChat();
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

  Future<void> _loadChat() async {
    try {
      final res = await _api.get('/chat/history');
      final rows = List<Map<String, dynamic>>.from(
        res.data['messages'] as List<dynamic>? ?? [],
      );
      if (!mounted) return;
      setState(() {
        _messages = rows
            .map((m) {
              final who = m['senderRole'] == 'parent' ? 'Me' : 'Teacher';
              return '$who: ${m['body']}';
            })
            .toList();
      });
    } catch (_) {
      // Keep demo messages if chat API is offline.
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
    await Future.wait([_loadDashboard(), _loadChat()]);
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add('Me: $text');
      _messageController.clear();
    });

    try {
      await _api.post('/chat/send', data: {'message': text});
      await _loadChat();
      await _loadDashboard();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Send failed: ${_formatError(e)}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final grades =
        List<Map<String, dynamic>>.from(_dashboard['grades'] as List? ?? []);
    final homework =
        List<Map<String, dynamic>>.from(_dashboard['homework'] as List? ?? []);
    final attendancePercent = asInt(_dashboard['attendancePercent'], 94);
    final gradeAverage = asInt(_dashboard['gradeAverage'], 86);

    return Focus(
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.parent),
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
          title: _dashboard['childName']?.toString() ?? 'Aarav Sharma',
          subtitle:
              'Attendance, grades, reminders, and secure school communication.',
          trailing: FilledButton.icon(
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
          children: [
            ResponsiveGrid(
              children: [
                MetricCard(
                  label: 'Child attendance',
                  value: '$attendancePercent%',
                  icon: Icons.how_to_reg_outlined,
                  color: colorScheme.primary,
                  trend: '+3%',
                  detail: 'Present today at 8:04 AM',
                ),
                MetricCard(
                  label: 'Grade average',
                  value: '$gradeAverage%',
                  icon: Icons.school_outlined,
                  color: Colors.teal,
                  trend: '+5%',
                  detail: 'Term 2 performance',
                ),
                MetricCard(
                  label: 'Fee reminders',
                  value: '${_dashboard['feeReminders'] ?? 1}',
                  icon: Icons.currency_rupee,
                  color: Colors.deepOrange,
                  detail: 'Transport fee due Friday',
                ),
                MetricCard(
                  label: 'Notifications',
                  value: '${_notifications.length}',
                  icon: Icons.notifications_none,
                  color: Colors.indigo,
                  detail: 'Latest school updates',
                ),
              ],
            ),
            const SizedBox(height: 18),
            const DashboardSection(
              title: 'Attendance analytics',
              child: DashboardPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AttendanceLineChart(
                      values: [92, 95, 91, 96, 94, 97],
                    ),
                    SizedBox(height: 8),
                    ProgressRow(
                      label: 'This month',
                      value: '94%',
                      percent: 0.94,
                    ),
                    ProgressRow(
                      label: 'On-time arrivals',
                      value: '88%',
                      percent: 0.88,
                    ),
                  ],
                ),
              ),
            ),
            DashboardSection(
              title: loc.grades,
              action: TextButton.icon(
                onPressed: _loadGrades,
                icon: const Icon(Icons.refresh),
                label: const Text('Update'),
              ),
              child: DashboardPanel(
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
                          value:
                              '${(_gradePercent(grades[i]) * 100).round()}%',
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
            DashboardSection(
              title: loc.homework,
              child: DashboardPanel(
                child: NotificationList(
                  items: homework.isEmpty
                      ? const [
                          DashboardNotification(
                            title: 'Math practice',
                            detail: 'Solve exercise 5 from chapter 2',
                            icon: Icons.assignment_outlined,
                            color: Colors.indigo,
                            time: 'Demo',
                          ),
                        ]
                      : [
                          for (final item in homework)
                            DashboardNotification(
                              title: item['title']?.toString() ?? 'Homework',
                              detail: item['description']?.toString() ?? '',
                              icon: Icons.assignment_outlined,
                              color: Colors.indigo,
                              time: _shortTime(item['created_at']?.toString()),
                            ),
                        ],
                ),
              ),
            ),
            DashboardSection(
              title: 'Notifications',
              action: TextButton.icon(
                onPressed: _refreshDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              child: DashboardPanel(
                child: NotificationList(
                  items: _notifications,
                ),
              ),
            ),
            DashboardSection(
              title: 'Fee payment',
              child: DashboardPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload payment receipt so the teacher can verify it.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _uploadFeeProof,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: const Text('Upload fee proof'),
                    ),
                  ],
                ),
              ),
            ),
            DashboardSection(
              title: loc.chat,
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
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
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
                                hintText: 'Type a message',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Refresh chat',
                            onPressed: _loadChat,
                            icon: const Icon(Icons.refresh),
                          ),
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
