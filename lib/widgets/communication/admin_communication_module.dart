import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../design_system/app_button.dart';
import 'activity_timeline.dart';
import 'communication_models.dart';
import 'notice_analytics_panel.dart';
import 'notice_composer.dart';
import 'notice_feed.dart';
import 'notification_toast.dart';

/// Admin broadcast dashboard with analytics and scheduling.
class AdminCommunicationModule extends StatefulWidget {
  const AdminCommunicationModule({super.key});

  @override
  State<AdminCommunicationModule> createState() =>
      _AdminCommunicationModuleState();
}

class _AdminCommunicationModuleState extends State<AdminCommunicationModule> {
  final ApiService _api = ApiService();
  int _tab = 0;
  bool _loading = true;
  List<NoticeItem> _notices = [];
  int _alerts = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/dashboard/admin');
      final data = Map<String, dynamic>.from(res.data as Map);
      final activity = List<Map<String, dynamic>>.from(
        data['recentActivity'] as List? ?? [],
      );
      if (!mounted) return;
      setState(() {
        _alerts = (data['alerts'] as num?)?.toInt() ?? 0;
        _notices = activity.asMap().entries.map((e) {
          return NoticeItem(
            id: 'admin-${e.key}',
            title: e.value['title']?.toString() ?? 'Activity',
            body: e.value['detail']?.toString() ?? '',
            category: NoticeCategory.announcement,
            priority: NoticePriority.normal,
            createdAt: DateTime.tryParse(
                  e.value['createdAt']?.toString() ?? '',
                ) ??
                DateTime.now(),
            audienceLabel: 'All school',
            deliveryCount: 1284,
            readCount: 1100,
          );
        }).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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

  Future<void> _publish({
    required String subject,
    required String body,
    required NoticeAudience audience,
    required List<String> classes,
    required List<NoticeAttachment> attachments,
    DateTime? scheduledAt,
  }) async {
    final notice = NoticeItem(
      id: 'broadcast-${DateTime.now().millisecondsSinceEpoch}',
      title: subject,
      body: body,
      category: NoticeCategory.announcement,
      priority: NoticePriority.urgent,
      createdAt: DateTime.now(),
      audience: audience,
      audienceLabel: classes.isEmpty ? 'All school' : classes.join(', '),
      isScheduled: scheduledAt != null,
      scheduledAt: scheduledAt,
      attachments: attachments,
      deliveryCount: 1284,
      readCount: 0,
    );
    setState(() => _notices.insert(0, notice));
    if (mounted) {
      NotificationToastHost.of(context)?.showToast(notice);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast queued for delivery')),
      );
    }
  }

  List<ActivityStreamItem> get _stream => _notices.map((n) {
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
    final totalSent = _notices.length + _alerts;
    final totalRead =
        _notices.fold<int>(0, (sum, n) => sum + (n.readCount ?? 0));
    final openRate = totalSent == 0 ? 0.0 : (totalRead / (totalSent * 200)) * 100;

    return NotificationToastHost(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Broadcast communications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              AppButton(
                label: 'Refresh',
                icon: Icons.refresh,
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: _load,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Broadcast'), icon: Icon(Icons.campaign_outlined, size: 16)),
                ButtonSegment(value: 1, label: Text('Compose'), icon: Icon(Icons.edit_note_outlined, size: 16)),
                ButtonSegment(value: 2, label: Text('Analytics'), icon: Icon(Icons.insights_outlined, size: 16)),
                ButtonSegment(value: 3, label: Text('Activity'), icon: Icon(Icons.history, size: 16)),
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
              emptyTitle: 'No broadcasts yet',
              emptyMessage: 'School-wide announcements appear here.',
            ),
          if (_tab == 1)
            NoticeComposer(
              onPublish: _publish,
              initialSubject: 'School-wide announcement',
            ),
          if (_tab == 2)
            NoticeAnalyticsPanel(
              totalSent: totalSent,
              totalRead: totalRead.clamp(0, totalSent * 200),
              openRate: openRate.clamp(0, 100),
            ),
          if (_tab == 3)
            ActivityTimeline(
              items: _stream,
              title: 'Announcement timeline',
            ),
        ],
      ),
    );
  }
}
