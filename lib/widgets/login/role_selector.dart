import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';

class RoleOption {
  const RoleOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });

  final String id;
  final String label;
  final IconData icon;
  final String description;
}

/// Segmented role picker with animated selection and hover feedback.
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onChanged,
    this.compact = false,
  });

  final List<RoleOption> options;
  final String selectedId;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactRoleSelector(
        options: options,
        selectedId: selectedId,
        onChanged: onChanged,
      );
    }
    return _ExpandedRoleSelector(
      options: options,
      selectedId: selectedId,
      onChanged: onChanged,
    );
  }
}

class _ExpandedRoleSelector extends StatelessWidget {
  const _ExpandedRoleSelector({
    required this.options,
    required this.selectedId,
    required this.onChanged,
  });

  final List<RoleOption> options;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          _RoleTile(
            option: options[i],
            selected: options[i].id == selectedId,
            onTap: () => onChanged(options[i].id),
          ),
          if (i < options.length - 1) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _CompactRoleSelector extends StatelessWidget {
  const _CompactRoleSelector({
    required this.options,
    required this.selectedId,
    required this.onChanged,
  });

  final List<RoleOption> options;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumn = constraints.maxWidth < 360;
        if (useColumn) {
          return Column(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                _RoleChip(
                  option: options[i],
                  selected: options[i].id == selectedId,
                  onTap: () => onChanged(options[i].id),
                  expand: true,
                ),
                if (i < options.length - 1) const SizedBox(height: AppSpacing.xs),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              Expanded(
                child: _RoleChip(
                  option: options[i],
                  selected: options[i].id == selectedId,
                  onTap: () => onChanged(options[i].id),
                ),
              ),
              if (i < options.length - 1) const SizedBox(width: AppSpacing.xs),
            ],
          ],
        );
      },
    );
  }
}

class _RoleTile extends StatefulWidget {
  const _RoleTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final RoleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RoleTile> createState() => _RoleTileState();
}

class _RoleTileState extends State<_RoleTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusMd,
            color: widget.selected
                ? scheme.primaryContainer.withValues(alpha: 0.65)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            border: Border.all(
              color: widget.selected
                  ? scheme.primary.withValues(alpha: 0.7)
                  : scheme.outlineVariant.withValues(
                      alpha: _hovered ? 0.85 : 0.55,
                    ),
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          transform: Matrix4.diagonal3Values(
            _hovered ? 1.01 : 1.0,
            _hovered ? 1.01 : 1.0,
            1.0,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppAnimations.fast,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: AppSpacing.borderRadiusSm,
                  gradient: widget.selected
                      ? LinearGradient(
                          colors: [scheme.primary, scheme.secondary],
                        )
                      : null,
                  color: widget.selected
                      ? null
                      : scheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(
                  widget.option.icon,
                  color: widget.selected ? scheme.onPrimary : scheme.primary,
                  size: AppSpacing.iconMd,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.label,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.option.description,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: widget.selected ? 1 : 0,
                duration: AppAnimations.fast,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatefulWidget {
  const _RoleChip({
    required this.option,
    required this.selected,
    required this.onTap,
    this.expand = false,
  });

  final RoleOption option;
  final bool selected;
  final VoidCallback onTap;
  final bool expand;

  @override
  State<_RoleChip> createState() => _RoleChipState();
}

class _RoleChipState extends State<_RoleChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusMd,
            color: widget.selected
                ? scheme.primaryContainer.withValues(alpha: 0.7)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
            border: Border.all(
              color: widget.selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          transform: Matrix4.diagonal3Values(
            _hovered ? 1.03 : 1.0,
            _hovered ? 1.03 : 1.0,
            1.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.option.icon,
                color: widget.selected ? scheme.primary : scheme.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                widget.option.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight:
                          widget.selected ? FontWeight.w700 : FontWeight.w500,
                      color: widget.selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
