import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/glass_card.dart';
import 'communication_models.dart';

/// Modern messaging panel with grouped bubbles and send animation.
class ChatPanel extends StatefulWidget {
  const ChatPanel({
    super.key,
    required this.messages,
    required this.controller,
    required this.onSend,
    this.onRefresh,
    this.title = 'Messages',
    this.hintText = 'Type a message…',
    this.isSending = false,
  });

  final List<ChatMessage> messages;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onRefresh;
  final String title;
  final String hintText;
  final bool isSending;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _sendAnim;

  @override
  void initState() {
    super.initState();
    _sendAnim = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    );
  }

  @override
  void dispose() {
    _sendAnim.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    await _sendAnim.forward();
    _sendAnim.reverse();
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: scheme.primary, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (widget.onRefresh != null)
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 280,
            child: widget.messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Start the conversation.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      return AppFadeIn(
                        delay: AppAnimations.staggerDelay(
                          index,
                          base: AppAnimations.instant,
                        ),
                        child: _MessageBubble(message: widget.messages[index]),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      isDense: true,
                      suffixIcon: widget.isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                ScaleTransition(
                  scale: Tween<double>(begin: 1, end: 0.9).animate(_sendAnim),
                  child: IconButton.filled(
                    tooltip: 'Send',
                    onPressed: widget.isSending ? null : _handleSend,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isMine = message.isMine;
    final timeFmt = DateFormat.jm();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          gradient: isMine
              ? LinearGradient(
                  colors: [
                    scheme.primary,
                    scheme.secondary.withValues(alpha: 0.85),
                  ],
                )
              : null,
          color: isMine ? null : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine && message.senderLabel != null)
              Text(
                message.senderLabel!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            Text(
              message.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isMine ? scheme.onPrimary : scheme.onSurface,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              timeFmt.format(message.timestamp.toLocal()),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isMine
                        ? scheme.onPrimary.withValues(alpha: 0.75)
                        : scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
