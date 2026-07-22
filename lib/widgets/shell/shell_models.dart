import 'package:flutter/material.dart';

/// A single navigation destination in the app shell.
class ShellNavItem {
  const ShellNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
    this.shortcut,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String? badge;
  final String? shortcut;

  IconData get activeIcon => selectedIcon ?? icon;
}

/// Notification shown in the shell notification center.
class ShellNotification {
  const ShellNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    this.time,
    this.isUnread = true,
  });

  final String id;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String? time;
  final bool isUnread;
}

/// Quick action surfaced via FAB or action panel.
class ShellQuickAction {
  const ShellQuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.description,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? description;
}

/// Role-specific navigation presets.
abstract final class ShellNavConfig {
  static const List<ShellNavItem> admin = [
    ShellNavItem(
      id: 'overview',
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      shortcut: '1',
    ),
    ShellNavItem(
      id: 'analytics',
      label: 'Analytics',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
      shortcut: '2',
    ),
    ShellNavItem(
      id: 'actions',
      label: 'Actions',
      icon: Icons.bolt_outlined,
      selectedIcon: Icons.bolt,
      shortcut: '3',
    ),
    ShellNavItem(
      id: 'users',
      label: 'Users',
      icon: Icons.manage_accounts_outlined,
      selectedIcon: Icons.manage_accounts,
      shortcut: '4',
    ),
    ShellNavItem(
      id: 'security',
      label: 'Security',
      icon: Icons.shield_outlined,
      selectedIcon: Icons.shield,
      shortcut: '5',
    ),
    ShellNavItem(
      id: 'activity',
      label: 'Activity',
      icon: Icons.history_outlined,
      selectedIcon: Icons.history,
      shortcut: '6',
    ),
  ];

  static const List<ShellNavItem> teacher = [
    ShellNavItem(
      id: 'overview',
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      shortcut: '1',
    ),
    ShellNavItem(
      id: 'attendance',
      label: 'Attendance',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
      shortcut: '2',
    ),
    ShellNavItem(
      id: 'students',
      label: 'Students',
      icon: Icons.groups_2_outlined,
      selectedIcon: Icons.groups_2,
      shortcut: '3',
    ),
    ShellNavItem(
      id: 'actions',
      label: 'Actions',
      icon: Icons.bolt_outlined,
      selectedIcon: Icons.bolt,
      shortcut: '4',
    ),
    ShellNavItem(
      id: 'messages',
      label: 'Messages',
      icon: Icons.chat_outlined,
      selectedIcon: Icons.chat,
      shortcut: '5',
    ),
  ];

  static const List<ShellNavItem> parent = [
    ShellNavItem(
      id: 'overview',
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      shortcut: '1',
    ),
    ShellNavItem(
      id: 'attendance',
      label: 'Attendance',
      icon: Icons.how_to_reg_outlined,
      selectedIcon: Icons.how_to_reg,
      shortcut: '2',
    ),
    ShellNavItem(
      id: 'grades',
      label: 'Grades',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
      shortcut: '3',
    ),
    ShellNavItem(
      id: 'ai_tutor',
      label: 'AI Study Buddy',
      icon: Icons.smart_toy_outlined,
      selectedIcon: Icons.smart_toy,
      shortcut: '4',
    ),
    ShellNavItem(
      id: 'homework',
      label: 'Homework',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      shortcut: '5',
    ),
    ShellNavItem(
      id: 'messages',
      label: 'Messages',
      icon: Icons.chat_outlined,
      selectedIcon: Icons.chat,
      shortcut: '6',
    ),
  ];

  static const List<ShellNavItem> student = [
    ShellNavItem(
      id: 'overview',
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      shortcut: '1',
    ),
    ShellNavItem(
      id: 'aiTutor',
      label: 'AI Tutor',
      icon: Icons.psychology_alt_outlined,
      selectedIcon: Icons.psychology_alt,
      shortcut: '2',
    ),
    ShellNavItem(
      id: 'study',
      label: 'Study',
      icon: Icons.auto_stories_outlined,
      selectedIcon: Icons.auto_stories,
      shortcut: '3',
    ),
  ];
}
