import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/app_button.dart';
import '../design_system/glass_card.dart';
import 'attachment_preview.dart';
import 'audience_selector.dart';
import 'communication_models.dart';
import 'notice_card.dart';

enum ComposeState { editing, draftSaved, sending, preview }

/// Rich notice compose screen with preview, audience, schedule, attachments.
class NoticeComposer extends StatefulWidget {
  const NoticeComposer({
    super.key,
    required this.onPublish,
    this.onSaveDraft,
    this.initialSubject,
    this.initialBody,
    this.showSchedule = true,
  });

  final Future<void> Function({
    required String subject,
    required String body,
    required NoticeAudience audience,
    required List<String> classes,
    required List<NoticeAttachment> attachments,
    DateTime? scheduledAt,
  }) onPublish;
  final VoidCallback? onSaveDraft;
  final String? initialSubject;
  final String? initialBody;
  final bool showSchedule;

  @override
  State<NoticeComposer> createState() => NoticeComposerState();
}

class NoticeComposerState extends State<NoticeComposer> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  NoticeAudience _audience = NoticeAudience.parents;
  List<String> _classes = ['Class 8A'];
  List<NoticeAttachment> _attachments = [];
  DateTime? _scheduledAt;
  ComposeState _state = ComposeState.editing;
  bool _showPreview = false;
  NoticeCategory _category = NoticeCategory.announcement;
  NoticePriority _priority = NoticePriority.normal;

  @override
  void initState() {
    super.initState();
    _subjectController.text = widget.initialSubject ?? '';
    _bodyController.text = widget.initialBody ?? '';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    setState(() {
      _attachments = [
        ..._attachments,
        NoticeAttachment(
          name: file.name,
          sizeLabel: '${(file.size / 1024).round()} KB',
        ),
      ];
    });
  }

  void _saveDraft() {
    setState(() => _state = ComposeState.draftSaved);
    widget.onSaveDraft?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Draft saved locally')),
    );
  }

  Future<void> _publish() async {
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and message are required')),
      );
      return;
    }

    setState(() => _state = ComposeState.sending);
    try {
      await widget.onPublish(
        subject: subject,
        body: body,
        audience: _audience,
        classes: _classes,
        attachments: _attachments,
        scheduledAt: _scheduledAt,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _scheduledAt != null
                ? 'Notice scheduled successfully'
                : 'Notice published successfully',
          ),
        ),
      );
      _subjectController.clear();
      _bodyController.clear();
      setState(() {
        _attachments = [];
        _scheduledAt = null;
        _state = ComposeState.editing;
        _showPreview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = ComposeState.editing);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish: $e')),
      );
    }
  }

  NoticeItem get _previewNotice => NoticeItem(
        id: 'preview',
        title: _subjectController.text.isEmpty
            ? 'Notice subject'
            : _subjectController.text,
        body: _bodyController.text.isEmpty
            ? 'Your announcement preview will appear here.'
            : _bodyController.text,
        category: _category,
        priority: _priority,
        createdAt: _scheduledAt ?? DateTime.now(),
        audience: _audience,
        audienceLabel: _classes.isEmpty ? 'All school' : _classes.join(', '),
        isScheduled: _scheduledAt != null,
        scheduledAt: _scheduledAt,
        attachments: _attachments,
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

    return AnimatedSwitcher(
      duration: AppAnimations.normal,
      child: isWide ? _buildSplit(context) : _buildStacked(context),
    );
  }

  Widget _buildStacked(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildEditor(context),
        if (_showPreview) ...[
          const SizedBox(height: AppSpacing.md),
          _buildPreviewPanel(context),
        ],
      ],
    );
  }

  Widget _buildSplit(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildEditor(context)),
        const SizedBox(width: AppSpacing.md),
        Expanded(flex: 2, child: _buildPreviewPanel(context)),
      ],
    );
  }

  Widget _buildEditor(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Compose notice',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              if (_state == ComposeState.draftSaved)
                Chip(
                  label: const Text('Draft saved'),
                  avatar: const Icon(Icons.save_outlined, size: 16),
                ),
              if (!MediaQuery.sizeOf(context).width.isNaN &&
                  MediaQuery.sizeOf(context).width < AppBreakpoints.desktop)
                IconButton(
                  tooltip: 'Toggle preview',
                  onPressed: () => setState(() => _showPreview = !_showPreview),
                  icon: Icon(
                    _showPreview ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _subjectController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Subject',
              hintText: 'Announcement title',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final c in NoticeCategory.values)
                FilterChip(
                  label: Text(c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                  avatar: Icon(c.icon, size: 14),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final p in NoticePriority.values)
                FilterChip(
                  label: Text(p.label),
                  selected: _priority == p,
                  onSelected: (_) => setState(() => _priority = p),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _bodyController,
            onChanged: (_) => setState(() {}),
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Write your announcement…',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AudienceSelector(
            selectedAudience: _audience,
            onAudienceChanged: (a) => setState(() => _audience = a),
            selectedClasses: _classes,
            onClassesChanged: (c) => setState(() => _classes = c),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              AppButton(
                label: 'Attach file',
                icon: Icons.attach_file,
                variant: AppButtonVariant.outline,
                size: AppButtonSize.sm,
                onPressed: _pickAttachment,
              ),
              const SizedBox(width: AppSpacing.sm),
              if (widget.showSchedule)
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (time == null) return;
                    setState(() {
                      _scheduledAt = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  },
                  icon: const Icon(Icons.schedule_send_outlined, size: 18),
                  label: Text(
                    _scheduledAt == null
                        ? 'Schedule'
                        : 'Scheduled ${_scheduledAt!.day}/${_scheduledAt!.month}',
                  ),
                ),
            ],
          ),
          if (_attachments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AttachmentPreviewList(
              attachments: _attachments,
              onRemove: (i) => setState(() => _attachments.removeAt(i)),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              AppButton(
                label: 'Save draft',
                icon: Icons.save_outlined,
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: _saveDraft,
              ),
              const Spacer(),
              AppButton(
                label: _scheduledAt != null ? 'Schedule' : 'Publish',
                icon: _scheduledAt != null
                    ? Icons.schedule_send
                    : Icons.send_rounded,
                onPressed: _state == ComposeState.sending ? null : _publish,
                isLoading: _state == ComposeState.sending,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live preview',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          NoticeCard(notice: _previewNotice, index: 0),
        ],
      ),
    );
  }
}
