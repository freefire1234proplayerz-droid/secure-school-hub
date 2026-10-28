import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../parent_dashboard.dart';
import '../../services/api_service.dart';
import '../../widgets/design_system/design_system.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  static const routeName = '/student/ai-tutor';

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final List<_TutorMessage> _messages = [
    _TutorMessage.ai(
      'Hi! Ask me about homework, science, math, history, or any school topic. I will explain it step by step.',
    ),
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _ask({String? question, bool replaceLastAnswer = false}) async {
    final prompt = (question ?? _questionController.text).trim();
    if (prompt.isEmpty || _isLoading) return;

    setState(() {
      if (replaceLastAnswer &&
          _messages.isNotEmpty &&
          !_messages.last.isStudent) {
        _messages.removeLast();
      } else {
        _messages.add(_TutorMessage.student(prompt));
      }
      _isLoading = true;
      _questionController.clear();
    });
    _scrollToBottom();

    try {
      final api = context.read<ApiService>();
      final response = await api.post('/ai/ask', data: {'question': prompt});
      final data = Map<String, dynamic>.from(response.data as Map);
      final answer = data['answer']?.toString().trim();

      if (answer == null || answer.isEmpty) {
        throw StateError('AI Tutor returned an empty answer.');
      }

      if (!mounted) return;
      setState(() {
        _messages.add(_TutorMessage.ai(answer));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(_formatError(error), isError: true);
    }
  }

  String _formatError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['error'] != null) {
        return data['error'].toString();
      }
      return error.message ?? 'Could not reach AI Tutor.';
    }
    return error.toString();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppAnimations.normal,
        curve: AppAnimations.standard,
      );
    });
  }

  void _clearConversation() {
    setState(() {
      _messages
        ..clear()
        ..add(
          _TutorMessage.ai(
            'Conversation cleared. What would you like to learn next?',
          ),
        );
    });
    _scrollToBottom();
  }

  Future<void> _copyAnswer(String answer) async {
    await Clipboard.setData(ClipboardData(text: answer));
    if (!mounted) return;
    _showSnack('Answer copied.');
  }

  void _regenerateLastAnswer() {
    final lastQuestion = _messages.lastWhere(
      (message) => message.isStudent,
      orElse: () => const _TutorMessage(
        text: '',
        isStudent: true,
        createdAt: null,
      ),
    );
    if (lastQuestion.text.isEmpty) return;
    _ask(question: lastQuestion.text, replaceLastAnswer: true);
  }

  void _returnToParentDashboard() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(ParentDashboard.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI Study Buddy'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _returnToParentDashboard,
        ),
        actions: [
          Tooltip(
            message: 'Close',
            child: IconButton(
              onPressed: _returnToParentDashboard,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
      body: GradientBackground(
        showOrbs: false,
        child: SafeArea(
          top: false,
          child: ResponsiveContainer(
            maxWidth: 1180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= AppBreakpoints.desktop;
                final chat = _TutorChatPanel(
                  messages: _messages,
                  scrollController: _scrollController,
                  isLoading: _isLoading,
                  onCopy: _copyAnswer,
                  onRegenerate: _regenerateLastAnswer,
                );

                return Column(
                  children: [
                    const _TutorBreadcrumb(),
                    const SizedBox(height: AppSpacing.sm),
                    _TutorHeader(
                      isLoading: _isLoading,
                      onClear: _clearConversation,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(
                                  width: 280,
                                  child: _StudyPromptPanel(),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(child: chat),
                              ],
                            )
                          : chat,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _QuestionComposer(
                      controller: _questionController,
                      focusNode: _focusNode,
                      enabled: !_isLoading,
                      onSubmit: () => _ask(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorBreadcrumb extends StatelessWidget {
  const _TutorBreadcrumb();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Text(
          'Parent Dashboard > AI Study Buddy',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TutorHeader extends StatelessWidget {
  const _TutorHeader({
    required this.isLoading,
    required this.onClear,
  });

  final bool isLoading;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.borderRadiusSm,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.psychology_alt_outlined, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Tutor',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoading
                      ? 'Working through your question'
                      : 'Friendly step-by-step help for school topics',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: 'Clear conversation',
            child: IconButton.filledTonal(
              onPressed: isLoading ? null : onClear,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorChatPanel extends StatelessWidget {
  const _TutorChatPanel({
    required this.messages,
    required this.scrollController,
    required this.isLoading,
    required this.onCopy,
    required this.onRegenerate,
  });

  final List<_TutorMessage> messages;
  final ScrollController scrollController;
  final bool isLoading;
  final ValueChanged<String> onCopy;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: messages.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length) {
            return const _TutorBubble(
              message: _TutorMessage(
                text: '',
                isStudent: false,
                createdAt: null,
              ),
              isTyping: true,
            );
          }
          final message = messages[index];
          return _TutorBubble(
            message: message,
            onCopy: message.isStudent ? null : () => onCopy(message.text),
            onRegenerate:
                message.isStudent || index != messages.length - 1 || isLoading
                    ? null
                    : onRegenerate,
          );
        },
      ),
    );
  }
}

class _TutorBubble extends StatelessWidget {
  const _TutorBubble({
    required this.message,
    this.isTyping = false,
    this.onCopy,
    this.onRegenerate,
  });

  final _TutorMessage message;
  final bool isTyping;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isStudent = message.isStudent;
    final bubbleColor = isStudent
        ? scheme.primary
        : scheme.surfaceContainerHighest.withValues(alpha: 0.78);
    final textColor = isStudent ? scheme.onPrimary : scheme.onSurface;

    return Align(
      alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppSpacing.radiusMd),
                topRight: const Radius.circular(AppSpacing.radiusMd),
                bottomLeft: Radius.circular(
                  isStudent ? AppSpacing.radiusMd : AppSpacing.radiusXs,
                ),
                bottomRight: Radius.circular(
                  isStudent ? AppSpacing.radiusXs : AppSpacing.radiusMd,
                ),
              ),
              border: Border.all(
                color: isStudent
                    ? scheme.primary.withValues(alpha: 0.12)
                    : scheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isTyping)
                    const _TypingIndicator()
                  else
                    SelectableText(
                      message.text,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            height: 1.45,
                          ),
                    ),
                  if (!isStudent && !isTyping) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        Tooltip(
                          message: 'Copy answer',
                          child: IconButton.filledTonal(
                            onPressed: onCopy,
                            icon: const Icon(Icons.copy_all_outlined),
                          ),
                        ),
                        Tooltip(
                          message: 'Regenerate answer',
                          child: IconButton.filledTonal(
                            onPressed: onRegenerate,
                            icon: const Icon(Icons.autorenew_rounded),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Transform.translate(
                  offset: Offset(
                    0,
                    -4 *
                        Curves.easeInOut.transform(
                          ((_controller.value + i * 0.2) % 1).clamp(0, 1),
                        ),
                  ),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuestionComposer extends StatelessWidget {
  const _QuestionComposer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                hintText: 'Ask a school question...',
                prefixIcon: Icon(Icons.edit_note_outlined),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Tooltip(
            message: 'Send question',
            child: IconButton.filled(
              onPressed: enabled ? onSubmit : null,
              icon: enabled
                  ? const Icon(Icons.send_rounded)
                  : const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyPromptPanel extends StatelessWidget {
  const _StudyPromptPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_stories_outlined, color: scheme.primary, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Study starters',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final prompt in const [
            'Explain photosynthesis',
            'Help me solve a fraction problem',
            'Summarize the water cycle',
            'Make a study plan for a test',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 17,
                    color: scheme.tertiary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      prompt,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
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

class _TutorMessage {
  const _TutorMessage({
    required this.text,
    required this.isStudent,
    required this.createdAt,
  });

  factory _TutorMessage.student(String text) {
    return _TutorMessage(
      text: text,
      isStudent: true,
      createdAt: DateTime.now(),
    );
  }

  factory _TutorMessage.ai(String text) {
    return _TutorMessage(
      text: text,
      isStudent: false,
      createdAt: DateTime.now(),
    );
  }

  final String text;
  final bool isStudent;
  final DateTime? createdAt;
}
