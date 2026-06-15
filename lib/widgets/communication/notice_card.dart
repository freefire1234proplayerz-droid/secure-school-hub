import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_animations.dart' show AppAnimations, AppFadeIn;
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'attachment_preview.dart';
import 'audience_selector.dart';
import 'communication_models.dart';
import 'message_badge.dart';

/// Rich announcement card with priority, read state, and attachments.
class NoticeCard extends StatefulWidget {
  const NoticeCard({
    super.key,
    required this.notice,
    this.onTap,
    this.onPin,
    this.onArchive,
    this.onMarkRead,
    this.selected = false,
    this.index = 0,
  });

  final NoticeItem notice;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onArchive;
  final VoidCallback? onMarkRead;
  final bool selected;
  final int index;

  @override
  State<NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<NoticeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final notice = widget.notice;
    final timeFmt = DateFormat.MMMd().add_jm();
    final priorityColor = notice.priority.color(scheme);

    return AppFadeIn(
      delay:
          AppAnimations.staggerDelay(widget.index, base: AppAnimations.instant),
      offset: const Offset(0, 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _hovered ? 1.01 : 1,
          duration: AppAnimations.fast,
          child: GlassCard(
            onTap: widget.onTap,
            variant: _hovered || widget.selected
                ? GlassCardVariant.elevated
                : GlassCardVariant.standard,
            tintColor: notice.priority == NoticePriority.urgent
                ? scheme.error.withValues(alpha: _hovered ? 0.08 : 0.05)
                : notice.isPinned
                    ? scheme.primary.withValues(alpha: 0.05)
                    : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            priorityColor.withValues(alpha: 0.22),
                            priorityColor.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Icon(
                        notice.category.icon,
                        color: priorityColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notice.title,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: notice.isRead
                                        ? scheme.onSurface
                                        : scheme.onSurface,
                                  ),
                                ),
                              ),
                              if (!notice.isRead) const UnreadPulse(),
                              if (notice.isPinned) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.push_pin_rounded,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _PriorityChip(priority: notice.priority),
                              _CategoryChip(category: notice.category),
                              if (notice.audienceLabel != null)
                                AudienceBadge(
                                  label: notice.audienceLabel!,
                                  icon: Icons.people_outline,
                                ),
                              if (notice.isScheduled)
                                const AudienceBadge(
                                  label: 'Scheduled',
                                  icon: Icons.schedule,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timeFmt.format(notice.createdAt.toLocal()),
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  notice.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                if (notice.attachments.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AttachmentPreviewList(
                    attachments: notice.attachments,
                    compact: true,
                  ),
                ],
                if (_hovered || widget.selected) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (!notice.isRead && widget.onMarkRead != null)
                        TextButton.icon(
                          onPressed: widget.onMarkRead,
                          icon: const Icon(Icons.mark_email_read_outlined,
                              size: 16),
                          label: const Text('Mark read'),
                        ),
                      if (widget.onPin != null)
                        TextButton.icon(
                          onPressed: widget.onPin,
                          icon: Icon(
                            notice.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            size: 16,
                          ),
                          label: Text(notice.isPinned ? 'Unpin' : 'Pin'),
                        ),
                      if (widget.onArchive != null)
                        TextButton.icon(
                          onPressed: widget.onArchive,
                          icon: const Icon(Icons.archive_outlined, size: 16),
                          label: const Text('Archive'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final NoticePriority priority;

  @override
  Widget build(BuildContext context) {
    final color = priority.color(Theme.of(context).colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppSpacing.borderRadiusXs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            priority.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final NoticeCategory category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppSpacing.borderRadiusXs,
      ),
      child: Text(
        category.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
