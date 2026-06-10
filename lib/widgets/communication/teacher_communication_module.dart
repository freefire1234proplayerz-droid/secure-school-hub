import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../dashboard/dashboard_grid.dart';
import '../design_system/glass_card.dart';
import 'activity_timeline.dart';
import 'chat_panel.dart';
import 'communication_models.dart';
import 'notice_composer.dart';
import 'notice_feed.dart';
import 'notification_toast.dart';
import 'push_settings_panel.dart';

/// Teacher communication: notices, compose, class chat, homework posting.
class TeacherCommunicationModule extends StatefulWidget {
  const TeacherCommunicationModule({super.key});

  @override
  State<TeacherCommunicationModule> createState() =>
      TeacherCommunicationModuleState();
}

class TeacherCommunicationModuleState extends State<TeacherCommunicationModule> {
  final ApiService _api = ApiService();
  final _chatController = TextEditingController();
  int _tab = 0;
  bool _loading = true;
  bool _sending = false;
  List<NoticeItem> _notices = [];
  List<ChatMessage> _messages = [];
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void openCompose() => setState(() => _tab = 1);

  int get unreadCount => _notices.where((n) => !n.isRead).length;

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.wait([_loadNotices(), _loadChat()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadNotices() async {
    try {
      final res = await _api.get('/dashboard/teacher');
      final rows = List<Map<String, dynamic>>.from(
        res.data['notifications'] as List? ?? [],
      );
      final homework = List<Map<String, dynamic>>.from(
        res.data['homework'] as List? ?? [],
      );
      if (!mounted) return;
      setState(() {
        _notices = [
          ...rows.asMap().entries.map(
                (e) => NoticeItem.fromApi(e.value, idPrefix: 'n-'),
              ),
          ...homework.asMap().entries.map(
                (e) => NoticeItem.fromHomework(e.value, e.key),
              ),
        ];
        _hasMore = _notices.length >= 10;
      });
    } catch (_) {
      // Keep demo notices if API offline.
    }
  }

  Future<void> _loadChat() async {
    try {
      final res = await _api.get('/chat/history');
      final rows = List<Map<String, dynamic>>.from(
        res.data['messages'] as List? ?? [],
      );
      if (!mounted) return;
      setState(() {
        _messages = rows
            .map((m) => ChatMessage.fromApi(m, 'teacher'))
            .toList();
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

  void _showLiveToast(NoticeItem notice) {
    NotificationToastHost.of(context)?.showToast(notice);
  }

  Future<void> _publishNotice({
    required String subject,
    required String body,
    required NoticeAudience audience,
    required List<String> classes,
    required List<NoticeAttachment> attachments,
    DateTime? scheduledAt,
  }) async {
    if (scheduledAt != null) {
      final draft = NoticeItem(
        id: 'sched-${DateTime.now().millisecondsSinceEpoch}',
        title: subject,
        body: body,
        category: NoticeCategory.announcement,
        priority: NoticePriority.normal,
        createdAt: DateTime.now(),
        isScheduled: true,
        scheduledAt: scheduledAt,
        attachments: attachments,
        audienceLabel: classes.join(', '),
      );
      setState(() => _notices.insert(0, draft));
      return;
    }

    await _api.post('/homework/create', data: {
      'title': subject,
      'description': body,
    });

    if (attachments.isNotEmpty) {
      final file = attachments.first;
      await _api.post('/homework/attach', data: {
        'fileName': file.name,
        'size': 1024,
        'title': subject,
      });
    }

    final notice = NoticeItem(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      title: subject,
      body: body,
      category: NoticeCategory.homework,
      priority: NoticePriority.warning,
      createdAt: DateTime.now(),
      audience: audience,
      audienceLabel: classes.join(', '),
      attachments: attachments,
    );
    if (mounted) {
      setState(() => _notices.insert(0, notice));
      _showLiveToast(notice);
    }
    await _loadNotices();
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
      await _loadNotices();
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

  Future<void> _quickHomework() async {
    setState(() => _tab = 1);
  }

  Future<void> _attachHomework() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attached ${file.name} — shared with parents.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_formatError(e))),
      );
    }
  }

  String _formatError(Object e) {
    if (e is DioException) return e.message ?? 'Request failed';
    return e.toString();
  }

  List<ActivityStreamItem> get _activity => _notices.take(8).map((n) {
        return ActivityStreamItem(
          title: n.title,
          subtitle: n.body,
          timestamp: n.createdAt,
          icon: n.category.icon,
          color: n.priority.color(Theme.of(context).colorScheme),
        );
      }).toList();

  @override
  Widget build(BuildContext context) {
    return NotificationToastHost(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Notice center'), icon: Icon(Icons.inbox_outlined, size: 16)),
                ButtonSegment(value: 1, label: Text('Compose'), icon: Icon(Icons.edit_note_outlined, size: 16)),
                ButtonSegment(value: 2, label: Text('Class chat'), icon: Icon(Icons.chat_outlined, size: 16)),
                ButtonSegment(value: 3, label: Text('Activity'), icon: Icon(Icons.history, size: 16)),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_tab == 0) ...[
            DashboardGrid(
              minItemWidth: 200,
              children: [
                GlassCard(
                  onTap: _quickHomework,
                  child: const _QuickActionTile(
                    icon: Icons.post_add_outlined,
                    label: 'Post homework',
                    subtitle: 'Notify all parents instantly',
                  ),
                ),
                GlassCard(
                  onTap: _attachHomework,
                  child: const _QuickActionTile(
                    icon: Icons.attach_file,
                    label: 'Attach worksheet',
                    subtitle: 'PDF, image, or document',
                  ),
                ),
                GlassCard(
                  onTap: () => setState(() => _tab = 2),
                  child: const _QuickActionTile(
                    icon: Icons.chat_bubble_outline,
                    label: 'Message parents',
                    subtitle: 'Encrypted class chat',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            NoticeFeed(
              notices: _notices,
              isLoading: _loading,
              hasMore: _hasMore,
              onLoadMore: () => setState(() => _hasMore = false),
              onRefresh: _load,
              onMarkRead: _markRead,
              onMarkAllRead: _markAllRead,
              onPin: _togglePin,
              onArchive: _archive,
            ),
          ],
          if (_tab == 1)
            NoticeComposer(
              onPublish: _publishNotice,
              initialSubject: 'Class announcement',
            ),
          if (_tab == 2)
            ChatPanel(
              messages: _messages,
              controller: _chatController,
              onSend: _sendChat,
              onRefresh: _loadChat,
              isSending: _sending,
              title: 'Encrypted parent-teacher messaging',
              hintText: 'Message parents',
            ),
          if (_tab == 3) ...[
            ActivityTimeline(items: _activity, title: 'Class discussion preview'),
            const SizedBox(height: AppSpacing.md),
            const PushSettingsPanel(),
          ],
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    );
  }
}
