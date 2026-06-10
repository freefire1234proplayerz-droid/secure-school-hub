import 'package:flutter/material.dart';

enum NoticePriority { urgent, warning, normal }

enum NoticeCategory {
  announcement,
  homework,
  attendance,
  fee,
  chat,
  emergency,
  general,
}

enum NoticeAudience { all, parents, teachers, admins, classTarget }

enum NoticeFeedFilter { all, unread, pinned, archived }

extension NoticePriorityX on NoticePriority {
  String get label => switch (this) {
        NoticePriority.urgent => 'Urgent',
        NoticePriority.warning => 'Warning',
        NoticePriority.normal => 'Normal',
      };

  Color color(ColorScheme scheme) => switch (this) {
        NoticePriority.urgent => scheme.error,
        NoticePriority.warning => Colors.deepOrange,
        NoticePriority.normal => scheme.primary,
      };

  IconData get icon => switch (this) {
        NoticePriority.urgent => Icons.priority_high_rounded,
        NoticePriority.warning => Icons.warning_amber_rounded,
        NoticePriority.normal => Icons.info_outline_rounded,
      };
}

extension NoticeCategoryX on NoticeCategory {
  String get label => switch (this) {
        NoticeCategory.announcement => 'Announcement',
        NoticeCategory.homework => 'Homework',
        NoticeCategory.attendance => 'Attendance',
        NoticeCategory.fee => 'Fees',
        NoticeCategory.chat => 'Message',
        NoticeCategory.emergency => 'Emergency',
        NoticeCategory.general => 'General',
      };

  IconData get icon => switch (this) {
        NoticeCategory.announcement => Icons.campaign_outlined,
        NoticeCategory.homework => Icons.assignment_outlined,
        NoticeCategory.attendance => Icons.how_to_reg_outlined,
        NoticeCategory.fee => Icons.receipt_long_outlined,
        NoticeCategory.chat => Icons.chat_bubble_outline,
        NoticeCategory.emergency => Icons.emergency_outlined,
        NoticeCategory.general => Icons.notifications_none,
      };
}

/// Rich notice model mapped from API notifications + local enrichments.
class NoticeItem {
  NoticeItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    required this.createdAt,
    this.audience = NoticeAudience.all,
    this.audienceLabel,
    this.isRead = false,
    this.isPinned = false,
    this.isArchived = false,
    this.isScheduled = false,
    this.scheduledAt,
    this.attachments = const [],
    this.readCount,
    this.deliveryCount,
  });

  final String id;
  final String title;
  final String body;
  final NoticeCategory category;
  final NoticePriority priority;
  final DateTime createdAt;
  final NoticeAudience audience;
  final String? audienceLabel;
  bool isRead;
  bool isPinned;
  bool isArchived;
  final bool isScheduled;
  final DateTime? scheduledAt;
  final List<NoticeAttachment> attachments;
  final int? readCount;
  final int? deliveryCount;

  factory NoticeItem.fromApi(Map<String, dynamic> json, {String? idPrefix}) {
    final type = json['type']?.toString() ?? 'general';
    final category = _categoryFromType(type);
    final priority = _priorityFromType(type, json['title']?.toString());
    final created = DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now();

    return NoticeItem(
      id: '${idPrefix ?? ''}${json['id'] ?? created.millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'School update',
      body: json['body']?.toString() ?? '',
      category: category,
      priority: priority,
      createdAt: created,
      isRead: json['read_at'] != null,
      audience: _audienceFromType(type),
      audienceLabel: _audienceLabelFromType(type),
    );
  }

  factory NoticeItem.fromHomework(Map<String, dynamic> json, int index) {
    final created = DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now();
    return NoticeItem(
      id: 'hw-$index-${created.millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Homework',
      body: json['description']?.toString() ?? '',
      category: NoticeCategory.homework,
      priority: NoticePriority.warning,
      createdAt: created,
      audience: NoticeAudience.parents,
      audienceLabel: 'Class 8A parents',
    );
  }

  static NoticeCategory _categoryFromType(String type) => switch (type) {
        'homework' => NoticeCategory.homework,
        'attendance' => NoticeCategory.attendance,
        'fee' => NoticeCategory.fee,
        'chat' => NoticeCategory.chat,
        _ => NoticeCategory.general,
      };

  static NoticePriority _priorityFromType(String type, String? title) {
    final t = (title ?? '').toLowerCase();
    if (t.contains('emergency') || t.contains('urgent')) {
      return NoticePriority.urgent;
    }
    if (type == 'fee' || type == 'homework') return NoticePriority.warning;
    return NoticePriority.normal;
  }

  static NoticeAudience _audienceFromType(String type) => switch (type) {
        'chat' => NoticeAudience.teachers,
        'homework' => NoticeAudience.parents,
        _ => NoticeAudience.all,
      };

  static String? _audienceLabelFromType(String type) => switch (type) {
        'homework' => 'Parents • Class 8A',
        'attendance' => 'Parents',
        'fee' => 'Parents',
        'chat' => 'Teachers',
        _ => 'All school',
      };

  NoticeItem copyWith({
    bool? isRead,
    bool? isPinned,
    bool? isArchived,
  }) {
    return NoticeItem(
      id: id,
      title: title,
      body: body,
      category: category,
      priority: priority,
      createdAt: createdAt,
      audience: audience,
      audienceLabel: audienceLabel,
      isRead: isRead ?? this.isRead,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isScheduled: isScheduled,
      scheduledAt: scheduledAt,
      attachments: attachments,
      readCount: readCount,
      deliveryCount: deliveryCount,
    );
  }
}

class NoticeAttachment {
  const NoticeAttachment({
    required this.name,
    required this.sizeLabel,
    this.mimeType,
  });

  final String name;
  final String sizeLabel;
  final String? mimeType;

  IconData get icon {
    final n = name.toLowerCase();
    if (n.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (n.endsWith('.png') || n.endsWith('.jpg')) return Icons.image_outlined;
    return Icons.attach_file;
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    required this.isMine,
    required this.timestamp,
    this.senderLabel,
  });

  final String id;
  final String body;
  final bool isMine;
  final DateTime timestamp;
  final String? senderLabel;

  factory ChatMessage.fromApi(Map<String, dynamic> json, String myRole) {
    final role = json['senderRole']?.toString();
    return ChatMessage(
      id: json['id']?.toString() ?? '${json['created_at']}',
      body: json['body']?.toString() ?? '',
      isMine: role == myRole,
      timestamp: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      senderLabel: role == myRole ? 'Me' : (role == 'teacher' ? 'Teacher' : 'Parent'),
    );
  }
}

class ActivityStreamItem {
  const ActivityStreamItem({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
}
