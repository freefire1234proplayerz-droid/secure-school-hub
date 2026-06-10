import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';

/// Push notification preferences UI (local settings display).
class PushSettingsPanel extends StatefulWidget {
  const PushSettingsPanel({super.key});

  @override
  State<PushSettingsPanel> createState() => _PushSettingsPanelState();
}

class _PushSettingsPanelState extends State<PushSettingsPanel> {
  bool _announcements = true;
  bool _homework = true;
  bool _attendance = true;
  bool _fees = true;
  bool _emergency = true;
  bool _chat = true;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Push notification settings',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _toggle('School announcements', _announcements, (v) => _announcements = v),
          _toggle('Homework reminders', _homework, (v) => _homework = v),
          _toggle('Attendance alerts', _attendance, (v) => _attendance = v),
          _toggle('Fee reminders', _fees, (v) => _fees = v),
          _toggle('Emergency broadcasts', _emergency, (v) => _emergency = v),
          _toggle('Direct messages', _chat, (v) => _chat = v),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: (v) => setState(() => onChanged(v)),
    );
  }
}
