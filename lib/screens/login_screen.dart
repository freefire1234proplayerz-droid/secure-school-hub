import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../widgets/design_system/design_system.dart';
import '../widgets/language_toggle.dart';
import '../widgets/login/floating_text_field.dart';
import '../widgets/login/particle_background.dart';
import '../widgets/login/role_selector.dart';
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
      duration: AppAnimations.slow,
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
      body: ParticleBackground(
        child: Focus(
          autofocus: true,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= AppBreakpoints.tablet;

                if (isWide) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Padding(
                        padding:
                            AppBreakpoints.pagePadding(constraints.maxWidth),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: AppFadeIn(
                                delay: AppAnimations.instant,
                                child: _BrandingPanel(
                                  title: loc.appTitle,
                                  subtitle:
                                      'Secure access for admins, teachers, and parents.',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xxl),
                            Expanded(
                              child: AppFadeIn(
                                delay: AppAnimations.fast,
                                offset: const Offset(24, 0),
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
                                  compactRoles: false,
                                ),
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
                    padding: AppBreakpoints.pagePadding(constraints.maxWidth),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.maxFormWidth,
                      ),
                      child: AppFadeIn(
                        child: Column(
                          children: [
                            _BrandingPanel(
                              title: loc.appTitle,
                              subtitle: 'Sign in to your school portal',
                              compact: true,
                            ),
                            const SizedBox(height: AppSpacing.lg),
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
                              compactRoles: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        AppPulse(
          minScale: 0.98,
          child: Container(
            width: compact ? 72 : 88,
            height: compact ? 72 : 88,
            decoration: BoxDecoration(
              borderRadius: AppSpacing.borderRadiusLg,
              gradient: AppGradients.heroAccent(scheme),
              boxShadow: AppShadows.primaryGlow(scheme.primary),
            ),
            child: Icon(
              Icons.shield_moon_rounded,
              size: compact ? 36 : 44,
              color: scheme.onPrimary,
            ),
          ),
        ),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
        Text(
          title,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: (compact ? textTheme.headlineMedium : textTheme.displaySmall)
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: AppSpacing.xl),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _FeatureBadge(
                icon: Icons.verified_user_outlined,
                label: '2FA secured',
              ),
              _FeatureBadge(
                icon: Icons.lock_outline,
                label: 'Encrypted sessions',
              ),
              _FeatureBadge(
                icon: Icons.devices_outlined,
                label: 'Multi-device',
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FeatureBadge extends StatefulWidget {
  const _FeatureBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  State<_FeatureBadge> createState() => _FeatureBadgeState();
}

class _FeatureBadgeState extends State<_FeatureBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: AppSpacing.borderRadiusSm,
          color: scheme.surfaceContainerHighest.withValues(
            alpha: _hovered ? 0.75 : 0.5,
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        transform: Matrix4.diagonal3Values(
          _hovered ? 1.04 : 1.0,
          _hovered ? 1.04 : 1.0,
          1.0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
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
    required this.compactRoles,
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
  final bool compactRoles;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      variant: GlassCardVariant.elevated,
      borderRadius: AppSpacing.borderRadiusXl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      blur: 20,
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
                          ? 'Enter the code sent to your email'
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Sign in as',
            style: AppTextStyles.overline(scheme),
          ),
          const SizedBox(height: AppSpacing.xs),
          RoleSelector(
            options: roles,
            selectedId: role,
            onChanged: onRoleChanged,
            compact: compactRoles,
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: AppAnimations.normal,
            switchInCurve: AppAnimations.enter,
            switchOutCurve: AppAnimations.exit,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: otpSent
                ? _OtpStepIndicator(key: const ValueKey('otp-step'), loc: loc)
                : const _CredentialsStepIndicator(
                    key: ValueKey('cred-step'),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppFadeIn(
                  delay: AppAnimations.staggerDelay(1),
                  child: FloatingTextField(
                    controller: emailController,
                    label: loc.email,
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppFadeIn(
                  delay: AppAnimations.staggerDelay(2),
                  child: FloatingTextField(
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
                ),
                SizeTransition(
                  sizeFactor: CurvedAnimation(
                    parent: otpRevealController,
                    curve: AppAnimations.emphasized,
                  ),
                  axisAlignment: -1,
                  child: FadeTransition(
                    opacity: otpRevealController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        if (auth.lastOtpDemo != null)
                          AppFadeIn(
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                borderRadius: AppSpacing.borderRadiusSm,
                                color: scheme.primaryContainer
                                    .withValues(alpha: 0.55),
                                border: Border.all(
                                  color: scheme.primary.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: scheme.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
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
                          ),
                        if (auth.lastOtpDemo != null)
                          const SizedBox(height: AppSpacing.sm),
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
                const SizedBox(height: AppSpacing.lg),
                AppFadeIn(
                  delay: AppAnimations.staggerDelay(3),
                  child: AppButton(
                    label: otpSent ? loc.verifyOtp : loc.sendOtp,
                    icon:
                        otpSent ? Icons.verified_outlined : Icons.send_rounded,
                    expand: true,
                    isLoading: auth.isLoading,
                    onPressed: auth.isLoading ? null : onSubmit,
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

class _CredentialsStepIndicator extends StatelessWidget {
  const _CredentialsStepIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StepIndicator(
      steps: ['Credentials', 'Verification'],
      activeIndex: 0,
    );
  }
}

class _OtpStepIndicator extends StatelessWidget {
  const _OtpStepIndicator({super.key, required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return _StepIndicator(
      steps: ['Credentials', loc.otp],
      activeIndex: 1,
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
              duration: AppAnimations.normal,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: i <= activeIndex
                    ? AppGradients.heroAccentSoft(scheme)
                    : null,
                color: i <= activeIndex ? null : scheme.surfaceContainerHighest,
              ),
            ),
          ),
          if (i < steps.length - 1) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}
