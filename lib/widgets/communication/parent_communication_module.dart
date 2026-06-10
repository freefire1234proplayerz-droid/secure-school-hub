import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'chat_panel.dart';
import 'communication_models.dart';
import 'notice_card.dart';
import 'notice_feed.dart';
import 'notification_toast.dart';
import 'push_settings_panel.dart';

/// Parent inbox: school alerts, homework, fees, attendance, chat.
class ParentCommunicationModule extends StatefulWidget {
  const ParentCommunicationModule({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ParentCommunicationModule> createState() =>
      ParentCommunicationModuleState();
}

class ParentCommunicationModuleState extends State<ParentCommunicationModule> {
  final ApiService _api = ApiService();
  final _chatController = TextEditingController();
  late int _tab;
  bool _loading = true;
  bool _sending = false;
  List<NoticeItem> _notices = [];
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 3);
    _load();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  int get unreadCount => _notices.where((n) => !n.isRead).length;

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.wait([_loadDashboard(), _loadChat()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadDashboard() async {
    try {
      final res = await _api.get('/dashboard/parent');
      final data = Map<String, dynamic>.from(res.data as Map);
      final rows = List<Map<String, dynamic>>.from(
        data['notifications'] as List? ?? [],
      );
      final homework = List<Map<String, dynamic>>.from(
        data['homework'] as List? ?? [],
      );
      if (!mounted) return;
      setState(() {
        _notices = [
          ...rows.asMap().entries.map(
                (e) => NoticeItem.fromApi(e.value, idPrefix: 'p-'),
              ),
          ...homework.asMap().entries.map(
                (e) => NoticeItem.fromHomework(e.value, e.key),
              ),
        ];
      });
    } catch (_) {
      await _loadFallbackNotifications();
    }
  }

  Future<void> _loadFallbackNotifications() async {
    try {
      final res = await _api.get('/attendance/notifications');
      final rows = List<Map<String, dynamic>>.from(
        res.data['notifications'] as List? ?? [],
      );
      if (!mounted || rows.isEmpty) return;
      setState(() {
        _notices = rows
            .asMap()
            .entries
            .map((e) => NoticeItem.fromApi(e.value, idPrefix: 'fb-'))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _loadChat() async {
    try {
      final res = await _api.get('/chat/history');
      final rows = List<Map<String, dynamic>>.from(
        res.data['messages'] as List? ?? [],
      );
      if (!mounted) return;
      setState(() {
        _messages = rows.map((m) => ChatMessage.fromApi(m, 'parent')).toList();
      });
    } catch (_) {}
  }

  void _markRead(String id) {
    setState(() {
      final i = _notices.indexWhere((n) => n.id == id);
      if (i >= 0) _notices[i].isRead = true;
    });
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notices) {
        n.isRead = true;
      }
    });
  }

  void _togglePin(String id) {
    setState(() {
      final i = _notices.indexWhere((n) => n.id == id);
      if (i >= 0) _notices[i].isPinned = !_notices[i].isPinned;
    });
  }

  void _archive(String id) {
    setState(() {
      final i = _notices.indexWhere((n) => n.id == id);
      if (i >= 0) _notices[i].isArchived = true;
    });
  }

  Future<void> _sendChat() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
      _messages.add(
        ChatMessage(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          body: text,
          isMine: true,
          timestamp: DateTime.now(),
          senderLabel: 'Me',
        ),
      );
      _chatController.clear();
    });
    try {
      await _api.post('/chat/send', data: {'message': text});
      await _loadChat();
      await _loadDashboard();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_formatError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _formatError(Object e) {
    if (e is DioException) return e.message ?? 'Request failed';
    return e.toString();
  }

  List<NoticeItem> get _homework =>
      _notices.where((n) => n.category == NoticeCategory.homework).toList();

  List<NoticeItem> get _attendance =>
      _notices.where((n) => n.category == NoticeCategory.attendance).toList();

  List<NoticeItem> get _fees =>
      _notices.where((n) => n.category == NoticeCategory.fee).toList();

  List<NoticeItem> get _emergency => _notices
      .where((n) => n.priority == NoticePriority.urgent)
      .toList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return NotificationToastHost(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Inbox'), icon: Icon(Icons.inbox_outlined, size: 16)),
                ButtonSegment(value: 1, label: Text('Alerts'), icon: Icon(Icons.notifications_active_outlined, size: 16)),
                ButtonSegment(value: 2, label: Text('Chat'), icon: Icon(Icons.chat_outlined, size: 16)),
                ButtonSegment(value: 3, label: Text('Settings'), icon: Icon(Icons.tune_outlined, size: 16)),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_tab == 0)
            NoticeFeed(
              notices: _notices,
              isLoading: _loading,
              onRefresh: _load,
              onMarkRead: _markRead,
              onMarkAllRead: _markAllRead,
              onPin: _togglePin,
              onArchive: _archive,
              emptyTitle: 'Inbox is clear',
              emptyMessage: 'School notices and homework updates appear here.',
            ),
          if (_tab == 1) ...[
            if (_emergency.isNotEmpty) ...[
              Text(
                'Emergency announcements',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.error,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final n in _emergency)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: NoticeCard(notice: n, index: 0),
                ),
            ],
            _AlertSection(
              title: 'Attendance alerts',
              icon: Icons.how_to_reg_outlined,
              color: Colors.teal,
              notices: _attendance,
            ),
            const SizedBox(height: AppSpacing.md),
            _AlertSection(
              title: 'Homework reminders',
              icon: Icons.assignment_outlined,
              color: Colors.indigo,
              notices: _homework,
            ),
            const SizedBox(height: AppSpacing.md),
            _AlertSection(
              title: 'Fee reminders',
              icon: Icons.receipt_long_outlined,
              color: Colors.deepOrange,
              notices: _fees,
            ),
          ],
          if (_tab == 2)
            ChatPanel(
              messages: _messages,
              controller: _chatController,
              onSend: _sendChat,
              onRefresh: _loadChat,
              isSending: _sending,
              title: 'Encrypted parent-teacher messaging',
            ),
          if (_tab == 3) const PushSettingsPanel(),
        ],
      ),
    );
  }
}

class _AlertSection extends StatelessWidget {
  const _AlertSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.notices,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<NoticeItem> notices;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (notices.isEmpty)
            Text(
              'No alerts in this category.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (var i = 0; i < notices.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: NoticeCard(notice: notices[i], index: i),
              ),
        ],
      ),
    );
  }
}
