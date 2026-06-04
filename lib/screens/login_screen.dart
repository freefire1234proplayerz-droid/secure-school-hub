import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../widgets/language_toggle.dart';
import 'admin/admin_dashboard.dart';
import 'teacher_dashboard.dart';
import 'parent_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  String _role = 'teacher';
  bool _otpSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    try {
      await auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _role,
      );
      if (!mounted) return;
      if (auth.tempUserId != null) {
        setState(() => _otpSent = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. No OTP received.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? (e.response?.data?['error'] ?? e.message ?? e.type.toString())
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $message'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final auth = context.read<AuthService>();
    try {
      await auth.verifyOtp(_otpController.text.trim());
      if (!mounted) return;
      if (_role == 'teacher') {
        Navigator.of(context).pushReplacementNamed(TeacherDashboard.routeName);
      } else if (_role == 'admin') {
        Navigator.of(context).pushReplacementNamed(AdminDashboard.routeName);
      } else {
        Navigator.of(context).pushReplacementNamed(ParentDashboard.routeName);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException
          ? (e.response?.data?['error'] ?? e.message ?? 'Network error')
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Verify failed: $message'),
            duration: const Duration(seconds: 4)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Focus(
        autofocus: true,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                margin: const EdgeInsets.all(24),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        loc.appTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const LanguageToggle(),
                      const SizedBox(height: 24),
                      ToggleButtons(
                        isSelected: [
                          _role == 'admin',
                          _role == 'teacher',
                          _role == 'parent',
                        ],
                        onPressed: (index) {
                          setState(() {
                            _role = switch (index) {
                              0 => 'admin',
                              1 => 'teacher',
                              _ => 'parent',
                            };
                            _otpSent = false;
                          });
                        },
                        constraints:
                            const BoxConstraints(minHeight: 44, minWidth: 100),
                        borderRadius: BorderRadius.circular(12),
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text('Admin'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(loc.teacher),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(loc.parent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: loc.email,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: loc.password,
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            if (_otpSent) ...[
                              if (auth.lastOtpDemo != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'For demo, use OTP: ${auth.lastOtpDemo} (valid for about 2 minutes)',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ),
                              TextFormField(
                                controller: _otpController,
                                decoration: InputDecoration(
                                  labelText: loc.otp,
                                  prefixIcon: const Icon(Icons.lock),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(88, 48),
                                ),
                                onPressed: auth.isLoading
                                    ? null
                                    : () async {
                                        if (_otpSent) {
                                          await _handleVerifyOtp();
                                        } else {
                                          await _handleLogin();
                                        }
                                      },
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _otpSent ? loc.verifyOtp : loc.sendOtp),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
