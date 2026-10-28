import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_system/app_button.dart';
import '../widgets/design_system/glass_card.dart';
import '../widgets/login/floating_text_field.dart';
import '../widgets/login/role_selector.dart';
import '../widgets/language_toggle.dart';
import 'admin/admin_dashboard.dart';
import 'teacher_dashboard.dart';
import 'parent_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  String _role = 'teacher';
  bool _otpSent = false;
  late final AnimationController _otpRevealController;

  @override
  void initState() {
    super.initState();
    _otpRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _otpRevealController.dispose();
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
        _otpRevealController.forward(from: 0);
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

  void _onRoleChanged(String role) {
    setState(() {
      _role = role;
      _otpSent = false;
      _otpRevealController.reset();
    });
  }

  List<RoleOption> _roleOptions(AppLocalizations loc) => [
        const RoleOption(
          id: 'admin',
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          description: 'Manage school operations & security',
        ),
        RoleOption(
          id: 'teacher',
          label: loc.teacher,
          icon: Icons.school_outlined,
          description: 'Attendance, homework & class tools',
        ),
        RoleOption(
          id: 'parent',
          label: loc.parent,
          icon: Icons.family_restroom_outlined,
          description: 'Track grades, fees & child updates',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final auth = context.watch<AuthService>();
    final roles = _roleOptions(loc);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            if (isWide) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth * 0.08,
                      vertical: 48,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _BrandingPanel(title: loc.appTitle, subtitle: 'Secure access for administrators, teachers, and parents.'),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          flex: 4,
                          child: _LoginFormCard(
                            loc: loc,
                            auth: auth,
                            roles: roles,
                            role: _role,
                            otpSent: _otpSent,
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            otpController: _otpController,
                            otpRevealController: _otpRevealController,
                            onRoleChanged: _onRoleChanged,
                            onSubmit: () async {
                              if (_otpSent) {
                                await _handleVerifyOtp();
                              } else {
                                await _handleLogin();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      _BrandingPanel(title: loc.appTitle, subtitle: 'Sign in to your school portal', compact: true),
                      const SizedBox(height: 32),
                      _LoginFormCard(
                        loc: loc,
                        auth: auth,
                        roles: roles,
                        role: _role,
                        otpSent: _otpSent,
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        otpController: _otpController,
                        otpRevealController: _otpRevealController,
                        onRoleChanged: _onRoleChanged,
                        onSubmit: () async {
                          if (_otpSent) {
                            await _handleVerifyOtp();
                          } else {
                            await _handleLogin();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 64 : 80,
          height: compact ? 64 : 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: scheme.primary,
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.shield_outlined,
            size: compact ? 32 : 40,
            color: scheme.onPrimary,
          ),
        ),
        SizedBox(height: compact ? 16 : 24),
        Text(
          title,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: (compact ? textTheme.headlineMedium : textTheme.displaySmall)
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.loc,
    required this.auth,
    required this.roles,
    required this.role,
    required this.otpSent,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.otpController,
    required this.otpRevealController,
    required this.onRoleChanged,
    required this.onSubmit,
  });

  final AppLocalizations loc;
  final AuthService auth;
  final List<RoleOption> roles;
  final String role;
  final bool otpSent;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController otpController;
  final AnimationController otpRevealController;
  final ValueChanged<String> onRoleChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      variant: GlassCardVariant.elevated,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.login,
                      style: AppTextStyles.sectionTitle(textTheme),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      otpSent
                          ? 'Enter the 6-digit code sent to your device'
                          : 'Choose your role and sign in',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const LanguageToggle(),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Sign in as',
            style: AppTextStyles.overline(scheme),
          ),
          const SizedBox(height: 8),
          RoleSelector(
            options: roles,
            selectedId: role,
            onChanged: onRoleChanged,
          ),
          const SizedBox(height: 24),
          _StepIndicator(
            steps: ['Credentials', loc.otp],
            activeIndex: otpSent ? 1 : 0,
          ),
          const SizedBox(height: 16),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FloatingTextField(
                  controller: emailController,
                  label: loc.email,
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                FloatingTextField(
                  controller: passwordController,
                  label: loc.password,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction:
                      otpSent ? TextInputAction.next : TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                SizeTransition(
                  sizeFactor: CurvedAnimation(
                    parent: otpRevealController,
                    curve: Curves.easeOutCubic,
                  ),
                  axisAlignment: -1,
                  child: FadeTransition(
                    opacity: otpRevealController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        if (auth.lastOtpDemo != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: scheme.primaryContainer
                                  .withValues(alpha: 0.5),
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Demo OTP: ${auth.lastOtpDemo} (valid ~2 min)',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: scheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (auth.lastOtpDemo != null)
                          const SizedBox(height: 12),
                        FloatingTextField(
                          controller: otpController,
                          label: loc.otp,
                          prefixIcon: Icons.pin_outlined,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!auth.isLoading) onSubmit();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: otpSent ? loc.verifyOtp : loc.sendOtp,
                  icon:
                      otpSent ? Icons.verified_outlined : Icons.send_rounded,
                  expand: true,
                  isLoading: auth.isLoading,
                  onPressed: auth.isLoading ? null : onSubmit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.steps,
    required this.activeIndex,
  });

  final List<String> steps;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: i <= activeIndex
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
              ),
            ),
          ),
          if (i < steps.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}