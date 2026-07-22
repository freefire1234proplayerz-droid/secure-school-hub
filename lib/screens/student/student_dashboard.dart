import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/dashboard/dashboard_grid.dart';
import '../../widgets/dashboard/dashboard_section.dart';
import '../../widgets/dashboard/kpi_stat_card.dart';
import '../../widgets/dashboard/quick_action_card.dart';
import '../../widgets/design_system/app_button.dart';
import '../../widgets/experience/production_experience.dart';
import '../../widgets/shell/app_shell.dart';
import '../login_screen.dart';
import 'ai_tutor_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  static const routeName = '/student';

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedNav = 0;

  final _sectionKeys = <String, GlobalKey>{
    for (final id in ['overview', 'aiTutor', 'study']) id: GlobalKey(),
  };

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _openAiTutor() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AiTutorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppShell(
      title: 'Student Workspace',
      navItems: ShellNavConfig.student,
      selectedIndex: _selectedNav,
      onNavSelected: (index) => setState(() => _selectedNav = index),
      sectionKeys: _sectionKeys,
      onLogout: _logout,
      quickActions: [
        ShellQuickAction(
          label: 'AI Tutor',
          icon: Icons.psychology_alt_outlined,
          description: 'Ask for step-by-step study help',
          onTap: _openAiTutor,
        ),
      ],
      notifications: const [
        ShellNotification(
          id: 'ai-tutor',
          title: 'AI Tutor ready',
          body: 'Ask questions and get friendly explanations.',
          icon: Icons.psychology_alt_outlined,
          color: Colors.indigo,
          time: 'Now',
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShellSection(
            sectionKey: _sectionKeys['overview']!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardPageHeader(
                  title: 'My Learning Hub',
                  subtitle:
                      'Study progress, school tasks, and friendly AI help in one place.',
                  trailing: AppButton(
                    label: 'Ask AI Tutor',
                    icon: Icons.psychology_alt_outlined,
                    onPressed: _openAiTutor,
                    size: AppButtonSize.sm,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardGrid(
                  children: [
                    KPIStatCard(
                      label: 'Study streak',
                      value: '5 days',
                      icon: Icons.local_fire_department_outlined,
                      color: scheme.primary,
                      detail: 'Keep learning a little every day',
                    ),
                    const KPIStatCard(
                      label: 'Questions asked',
                      value: '0',
                      icon: Icons.help_outline_rounded,
                      color: Colors.indigo,
                      detail: 'AI Tutor chat history stays on this device',
                    ),
                    const KPIStatCard(
                      label: 'Homework focus',
                      value: 'Today',
                      icon: Icons.assignment_outlined,
                      color: Colors.teal,
                      detail: 'Use AI Tutor for hints and steps',
                    ),
                  ],
                ),
              ],
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['aiTutor']!,
            child: DashboardSection(
              title: 'AI Tutor',
              useGlassPanel: false,
              child: DashboardGrid(
                minItemWidth: 280,
                children: [
                  QuickActionCard(
                    label: 'Open AI Tutor',
                    description:
                        'Chat with a friendly school teacher assistant',
                    icon: Icons.psychology_alt_outlined,
                    color: Colors.indigo,
                    onTap: _openAiTutor,
                  ),
                  QuickActionCard(
                    label: 'Ask for math steps',
                    description: 'Get clear working for equations and problems',
                    icon: Icons.calculate_outlined,
                    color: Colors.teal,
                    onTap: _openAiTutor,
                  ),
                  QuickActionCard(
                    label: 'Explain a concept',
                    description: 'Break science and social studies into basics',
                    icon: Icons.auto_stories_outlined,
                    color: Colors.deepOrange,
                    onTap: _openAiTutor,
                  ),
                ],
              ),
            ),
          ),
          ShellSection(
            sectionKey: _sectionKeys['study']!,
            child: const DashboardSection(
              title: 'Study snapshot',
              useGlassPanel: false,
              animate: false,
              child: PersonalizableDashboardStrip(
                items: [
                  DashboardWidgetItem(
                    id: 'math-help',
                    title: 'Math practice',
                    subtitle: 'Ask for steps, then try the next one yourself.',
                    icon: Icons.functions_outlined,
                    color: Colors.teal,
                  ),
                  DashboardWidgetItem(
                    id: 'science',
                    title: 'Science concepts',
                    subtitle: 'Turn hard chapters into simple explanations.',
                    icon: Icons.science_outlined,
                    color: Colors.indigo,
                  ),
                  DashboardWidgetItem(
                    id: 'revision',
                    title: 'Revision plan',
                    subtitle: 'Prepare short daily plans for upcoming tests.',
                    icon: Icons.event_note_outlined,
                    color: Colors.deepOrange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
