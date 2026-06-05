import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../services/local_db.dart';

/// Wraps a screen and redirects to login when there is no valid session.
class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.child,
    this.allowedRoles = const [],
  });

  final Widget child;
  final List<String> allowedRoles;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    final auth = context.read<AuthService>();
    if (!LocalDb.hasSession) {
      _redirectToLogin();
      return;
    }

    final ok = auth.isAuthenticated && auth.role != null
        ? true
        : await auth.restoreSession();

    if (!mounted) return;

    if (!ok) {
      _redirectToLogin();
      return;
    }

    if (widget.allowedRoles.isNotEmpty &&
        !auth.canAccessRole(widget.allowedRoles.first) &&
        !(auth.role == 'admin')) {
      final allowed = widget.allowedRoles.any(auth.canAccessRole);
      if (!allowed && auth.role != 'admin') {
        _redirectToLogin();
        return;
      }
    }

    setState(() => _checking = false);
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}
