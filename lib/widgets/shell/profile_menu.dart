import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/frontend_stability_service.dart';
import '../../theme/app_spacing.dart';
import '../../providers/locale_provider.dart';

/// User profile dropdown with account info and actions.
class ProfileMenu extends StatefulWidget {
  const ProfileMenu({
    super.key,
    required this.onLogout,
    this.onRefresh,
    this.onMenuWillOpen,
  });

  final VoidCallback onLogout;
  final VoidCallback? onRefresh;
  final VoidCallback? onMenuWillOpen;

  @override
  State<ProfileMenu> createState() => ProfileMenuState();
}

class ProfileMenuState extends State<ProfileMenu> {
  final MenuController _controller = MenuController();
  final _stability = FrontendStabilityService.instance;

  @override
  void initState() {
    super.initState();
    _stability.registerCleanup(closeMenu);
    _trace('init');
  }

  @override
  void dispose() {
    _trace('dispose');
    _stability.unregisterCleanup(closeMenu);
    closeMenu();
    super.dispose();
  }

  void closeMenu() {
    if (!_controller.isOpen) return;
    _trace('close requested');
    _controller.close();
  }

  void _toggleMenu() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_controller.isOpen) {
      _trace('avatar click close');
      _controller.close();
      return;
    }
    widget.onMenuWillOpen?.call();
    _trace('avatar click open');
    _controller.open();
  }

  void _handleLogout() {
    closeMenu();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLogout();
    });
  }

  void _trace(String message) {
    assert(() {
      debugPrint('[ProfileMenu] $message');
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) {
    _trace('build');
    final scheme = Theme.of(context).colorScheme;
    final email = context.select<AuthService, String?>((auth) => auth.email) ??
        'user@school.edu';
    final role =
        context.select<AuthService, String?>((auth) => auth.role) ?? 'user';
    final localeCode = context.select<LocaleProvider, String>(
        (provider) => provider.locale.languageCode);
    final initials = _initials(email);

    return MenuAnchor(
      controller: _controller,
      onOpen: () => _trace('opened'),
      onClose: () => _trace('closed'),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          scheme.surface,
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
        ),
        elevation: const WidgetStatePropertyAll(6),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: AppSpacing.xs),
        ),
      ),
      builder: (context, controller, child) {
        return IconButton(
          tooltip: 'Account',
          onPressed: _toggleMenu,
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              initials,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onPrimaryContainer,
                  ),
            ),
          ),
        );
      },
      menuChildren: [
        _ProfileSummary(email: email, role: role),
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.language_outlined, size: 20),
          onPressed: () {
            closeMenu();
            context.read<LocaleProvider>().toggleLocale();
          },
          child: Text(
              localeCode == 'en' ? 'Switch to Hindi' : 'Switch to English'),
        ),
        if (widget.onRefresh != null)
          MenuItemButton(
            leadingIcon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              closeMenu();
              widget.onRefresh!();
            },
            child: const Text('Refresh data'),
          ),
        MenuItemButton(
          leadingIcon:
              Icon(Icons.logout_rounded, size: 20, color: scheme.error),
          onPressed: _handleLogout,
          child: Text('Sign out', style: TextStyle(color: scheme.error)),
        ),
      ],
    );
  }

  String _initials(String email) {
    final parts = email.split('@').first.split(RegExp(r'[._-]'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.email, required this.role});

  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: SizedBox(
        width: 240,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              role.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
