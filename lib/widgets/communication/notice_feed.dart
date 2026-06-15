import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import '../design_system/app_button.dart';
import '../design_system/glass_card.dart';
import 'communication_models.dart';
import 'message_badge.dart';
import 'notice_card.dart';

/// Searchable notice feed with filters, bulk actions, and infinite scroll.
class NoticeFeed extends StatefulWidget {
  const NoticeFeed({
    super.key,
    required this.notices,
    required this.onMarkRead,
    required this.onMarkAllRead,
    required this.onPin,
    required this.onArchive,
    this.onRefresh,
    this.isLoading = false,
    this.onLoadMore,
    this.hasMore = false,
    this.emptyTitle = 'No notices yet',
    this.emptyMessage = 'Announcements and updates will appear here.',
  });

  final List<NoticeItem> notices;
  final void Function(String id) onMarkRead;
  final VoidCallback onMarkAllRead;
  final void Function(String id) onPin;
  final void Function(String id) onArchive;
  final VoidCallback? onRefresh;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final String emptyTitle;
  final String emptyMessage;

  @override
  State<NoticeFeed> createState() => _NoticeFeedState();
}

class _NoticeFeedState extends State<NoticeFeed> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  NoticeFeedFilter _filter = NoticeFeedFilter.all;
  NoticeCategory? _category;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.onLoadMore == null) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      widget.onLoadMore!();
    }
  }

  List<NoticeItem> get _visible {
    var list = [...widget.notices];
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    list = switch (_filter) {
      NoticeFeedFilter.unread => list.where((n) => !n.isRead).toList(),
      NoticeFeedFilter.pinned => list.where((n) => n.isPinned).toList(),
      NoticeFeedFilter.archived => list.where((n) => n.isArchived).toList(),
      NoticeFeedFilter.all => list.where((n) => !n.isArchived).toList(),
    };

    if (_category != null) {
      list = list.where((n) => n.category == _category).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where(
            (n) =>
                n.title.toLowerCase().contains(q) ||
                n.body.toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
  }

  int get _unreadCount => widget.notices.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search notices…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _unreadCount > 0
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: MessageBadge(
                            count: _unreadCount,
                            showPulse: true,
                            compact: true,
                          ),
                        )
                      : null,
                  isDense: true,
                  border: const OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in NoticeFeedFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: FilterChip(
                          label: Text(_filterLabel(f)),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    for (final c in NoticeCategory.values)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: FilterChip(
                          label: Text(c.label),
                          selected: _category == c,
                          onSelected: (selected) => setState(
                            () => _category = selected ? c : null,
                          ),
                          avatar: Icon(c.icon, size: 14),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (widget.onRefresh != null)
                    AppButton(
                      label: 'Refresh',
                      icon: Icons.refresh,
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.sm,
                      onPressed: widget.onRefresh,
                    ),
                  const Spacer(),
                  if (_unreadCount > 0)
                    AppButton(
                      label: 'Mark all read',
                      icon: Icons.done_all,
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.sm,
                      onPressed: widget.onMarkAllRead,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.isLoading)
          const _FeedShimmer()
        else if (visible.isEmpty)
          _FeedEmpty(
            title: widget.emptyTitle,
            message: widget.emptyMessage,
          )
        else
          ListView.separated(
            controller: _scrollController,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length + (widget.hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index >= visible.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final notice = visible[index];
              return NoticeCard(
                notice: notice,
                index: index,
                onMarkRead: () => widget.onMarkRead(notice.id),
                onPin: () => widget.onPin(notice.id),
                onArchive: () => widget.onArchive(notice.id),
              );
            },
          ),
      ],
    );
  }

  String _filterLabel(NoticeFeedFilter f) => switch (f) {
        NoticeFeedFilter.all => 'All',
        NoticeFeedFilter.unread => 'Unread',
        NoticeFeedFilter.pinned => 'Pinned',
        NoticeFeedFilter.archived => 'Archived',
      };
}

class _FeedEmpty extends StatefulWidget {
  const _FeedEmpty({required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<_FeedEmpty> createState() => _FeedEmptyState();
}

class _FeedEmptyState extends State<_FeedEmpty>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slower,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            children: [
              Transform.translate(
                offset: Offset(0, -4 * _controller.value),
                child: Icon(
                  Icons.inbox_outlined,
                  size: 56,
                  color: scheme.primary
                      .withValues(alpha: 0.5 + 0.2 * _controller.value),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeedShimmer extends StatelessWidget {
  const _FeedShimmer();

  @override
  Widget build(BuildContext context) {
    final shimmer =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);

    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: shimmer,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
            ),
          ),
      ],
    );
  }
}
