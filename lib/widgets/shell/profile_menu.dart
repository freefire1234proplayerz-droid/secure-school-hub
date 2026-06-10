import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_spacing.dart';
import '../language_toggle.dart';

/// User profile dropdown with account info and actions.
class ProfileMenu extends StatelessWidget {
  const ProfileMenu({
    super.key,
    required this.onLogout,
    this.onRefresh,
  });

  final VoidCallback onLogout;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final scheme = Theme.of(context).colorScheme;
    final email = auth.email ?? 'user@school.edu';
    final role = auth.role ?? 'user';
    final initials = _initials(email);

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          scheme.surface.withValues(alpha: 0.96),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusMd),
        ),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
      builder: (context, controller, child) {
        return IconButton(
          tooltip: 'Account',
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                email,
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
        const Divider(height: 1),
        MenuItemButton(
          leadingIcon: const Icon(Icons.language_outlined, size: 20),
          child: const LanguageToggle(),
        ),
        if (onRefresh != null)
          MenuItemButton(
            leadingIcon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              onRefresh!();
            },
            child: const Text('Refresh data'),
          ),
        MenuItemButton(
          leadingIcon: Icon(Icons.logout_rounded, size: 20, color: scheme.error),
          onPressed: onLogout,
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
