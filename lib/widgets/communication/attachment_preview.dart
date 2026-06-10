import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'communication_models.dart';

/// Attachment chip / preview for notices and compose UI.
class AttachmentPreview extends StatefulWidget {
  const AttachmentPreview({
    super.key,
    required this.attachment,
    this.onRemove,
    this.onTap,
    this.compact = false,
  });

  final NoticeAttachment attachment;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<AttachmentPreview> createState() => _AttachmentPreviewState();
}

class _AttachmentPreviewState extends State<AttachmentPreview> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.02 : 1,
        duration: AppAnimations.fast,
        child: GlassCard(
          onTap: widget.onTap,
          variant: _hovered ? GlassCardVariant.elevated : GlassCardVariant.flat,
          padding: EdgeInsets.all(widget.compact ? AppSpacing.xs : AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.compact ? 32 : 40,
                height: widget.compact ? 32 : 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  widget.attachment.icon,
                  size: widget.compact ? 16 : 20,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.attachment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      widget.attachment.sizeLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (widget.onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: widget.onRemove,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal list of attachment previews.
class AttachmentPreviewList extends StatelessWidget {
  const AttachmentPreviewList({
    super.key,
    required this.attachments,
    this.onRemove,
    this.compact = false,
  });

  final List<NoticeAttachment> attachments;
  final void Function(int index)? onRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < attachments.length; i++)
          AttachmentPreview(
            attachment: attachments[i],
            compact: compact,
            onRemove: onRemove != null ? () => onRemove!(i) : null,
          ),
      ],
    );
  }
}
