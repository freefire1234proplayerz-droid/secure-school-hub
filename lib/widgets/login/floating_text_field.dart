import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

/// Text field with focus glow, hover lift, and shake on validation error.
class FloatingTextField extends StatefulWidget {
  const FloatingTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<FloatingTextField> createState() => _FloatingTextFieldState();
}

class _FloatingTextFieldState extends State<FloatingTextField>
    with SingleTickerProviderStateMixin {
  final _focusNode = FocusNode();
  bool _hovered = false;
  bool _obscured = true;
  bool _hasError = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _focusNode.addListener(() => setState(() {}));
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  void _shake() {
    _shakeController.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final focused = _focusNode.hasFocus;

    final glow = _hasError
        ? [
            BoxShadow(
              color: scheme.error.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ]
        : focused
            ? AppShadows.primaryGlow(scheme.primary)
            : AppShadows.none;

    final lift = (_hovered || focused) ? -2.0 : 0.0;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeAnimation.value, lift),
        child: child,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          curve: AppAnimations.standard,
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusMd,
            boxShadow: glow,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText && _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            onFieldSubmitted: widget.onFieldSubmitted,
            onChanged: (_) {
              if (_hasError) setState(() => _hasError = false);
            },
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? AnimatedScale(
                      scale: focused ? 1.08 : 1.0,
                      duration: AppAnimations.fast,
                      child: Icon(
                        widget.prefixIcon,
                        color: _hasError
                            ? scheme.error
                            : focused
                                ? scheme.primary
                                : null,
                      ),
                    )
                  : null,
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: AppSpacing.iconSm,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    )
                  : _hasError
                      ? Icon(Icons.error_outline, color: scheme.error, size: 20)
                      : null,
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(
                alpha: brightness == Brightness.dark ? 0.42 : 0.55,
              ),
            ),
            validator: (value) {
              final result = widget.validator?.call(value);
              if (result != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() => _hasError = true);
                    _shake();
                  }
                });
              }
              return result;
            },
          ),
        ),
      ),
    );
  }
}
