import 'package:flutter/material.dart';

/// Local attendance status for manual marking UI (not all states persist via API).
enum AttendanceStatus { present, absent, late, unmarked }

extension AttendanceStatusX on AttendanceStatus {
  String get label => switch (this) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.absent => 'Absent',
        AttendanceStatus.late => 'Late',
        AttendanceStatus.unmarked => 'Unmarked',
      };

  IconData get icon => switch (this) {
        AttendanceStatus.present => Icons.check_circle_outline,
        AttendanceStatus.absent => Icons.cancel_outlined,
        AttendanceStatus.late => Icons.schedule,
        AttendanceStatus.unmarked => Icons.radio_button_unchecked,
      };

  Color color(ColorScheme scheme) => switch (this) {
        AttendanceStatus.present => Colors.teal,
        AttendanceStatus.absent => scheme.error,
        AttendanceStatus.late => Colors.deepOrange,
        AttendanceStatus.unmarked => scheme.onSurfaceVariant,
      };
}

/// A student row enriched with local attendance state.
class StudentAttendanceRecord {
  StudentAttendanceRecord({
    required this.id,
    required this.name,
    required this.className,
    required this.rollNo,
    required this.qrPayload,
    this.status = AttendanceStatus.unmarked,
    this.markedAt,
  });

  final int id;
  final String name;
  final String className;
  final String rollNo;
  final String qrPayload;
  AttendanceStatus status;
  DateTime? markedAt;

  factory StudentAttendanceRecord.fromApi(Map<String, dynamic> json) {
    return StudentAttendanceRecord(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? 'Student',
      className: json['className']?.toString() ?? '',
      rollNo: json['rollNo']?.toString() ?? '',
      qrPayload: json['qrPayload']?.toString() ?? json['qrCode']?.toString() ?? '',
    );
  }

  StudentAttendanceRecord copyWith({
    AttendanceStatus? status,
    DateTime? markedAt,
  }) {
    return StudentAttendanceRecord(
      id: id,
      name: name,
      className: className,
      rollNo: rollNo,
      qrPayload: qrPayload,
      status: status ?? this.status,
      markedAt: markedAt ?? this.markedAt,
    );
  }
}

/// Result of a QR scan attempt.
class ScanHistoryEntry {
  const ScanHistoryEntry({
    required this.studentName,
    required this.className,
    required this.timestamp,
    required this.success,
    this.message,
  });

  final String studentName;
  final String className;
  final DateTime timestamp;
  final bool success;
  final String? message;
}

/// Activity item for attendance timeline feeds.
class AttendanceActivityItem {
  const AttendanceActivityItem({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.status,
    this.icon,
  });

  final String title;
  final String subtitle;
  final DateTime timestamp;
  final AttendanceStatus status;
  final IconData? icon;
}

/// Class-wise attendance summary card data.
class ClassAttendanceSummary {
  const ClassAttendanceSummary({
    required this.className,
    required this.present,
    required this.total,
    this.late = 0,
  });

  final String className;
  final int present;
  final int total;
  final int late;

  int get absent => (total - present - late).clamp(0, total);
  double get percent => total == 0 ? 0 : present / total;
}

/// Session timing block for class management UI.
class AttendanceSessionInfo {
  const AttendanceSessionInfo({
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    this.subject,
  });

  final String label;
  final String startTime;
  final String endTime;
  final bool isActive;
  final String? subject;
}
