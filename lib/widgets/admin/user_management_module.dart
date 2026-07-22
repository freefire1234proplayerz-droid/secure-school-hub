import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../dashboard/dashboard_grid.dart';
import '../dashboard/kpi_stat_card.dart';
import '../design_system/app_button.dart';
import '../design_system/glass_card.dart';

class UserManagementModule extends StatefulWidget {
  const UserManagementModule({super.key});

  @override
  State<UserManagementModule> createState() => _UserManagementModuleState();
}

class _UserManagementModuleState extends State<UserManagementModule> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Password@123');
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gradeController = TextEditingController(text: '8');
  final _sectionController = TextEditingController(text: 'A');
  final _rollController = TextEditingController();
  final _resetController = TextEditingController(text: 'Password@123');

  bool _loading = true;
  bool _saving = false;
  String _createRole = 'student';
  String _filterRole = 'all';
  String _status = 'all';
  String _classFilter = 'all';
  int? _parentUserId;
  int? _selectedUserId;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _parents = [];
  List<Map<String, dynamic>> _logs = [];
  Map<String, dynamic> _dashboard = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _gradeController.dispose();
    _sectionController.dispose();
    _rollController.dispose();
    _resetController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      await Future.wait(
          [_loadUsers(), _loadParents(), _loadDashboard(), _loadLogs()]);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadUsers() async {
    final res = await _api.get('/admin/users', query: {
      'role': _filterRole,
      'status': _status,
      'class': _classFilter,
      'search': _searchController.text.trim(),
    });
    if (!mounted) return;
    setState(() {
      _users =
          List<Map<String, dynamic>>.from(res.data['users'] as List? ?? []);
      _selectedUserId =
          _users.isEmpty ? null : _selectedUserId ?? _users.first['id'] as int?;
    });
  }

  Future<void> _loadParents() async {
    final res = await _api.get('/admin/parents');
    if (!mounted) return;
    setState(() {
      _parents =
          List<Map<String, dynamic>>.from(res.data['parents'] as List? ?? []);
      _parentUserId ??= _parents.isEmpty ? null : _parents.first['id'] as int?;
    });
  }

  Future<void> _loadDashboard() async {
    final res = await _api.get('/admin/dashboard');
    if (mounted) {
      setState(() => _dashboard = Map<String, dynamic>.from(res.data as Map));
    }
  }

  Future<void> _loadLogs() async {
    final res = await _api.get('/admin/audit-logs');
    if (mounted) {
      setState(() => _logs =
          List<Map<String, dynamic>>.from(res.data['logs'] as List? ?? []));
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _api.post('/admin/users', data: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': _createRole,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (_createRole == 'student') ...{
          'grade': _gradeController.text.trim(),
          'section': _sectionController.text.trim(),
          'rollNo': _rollController.text.trim(),
          'parentUserId': _parentUserId,
        },
      });
      _emailController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _phoneController.clear();
      _rollController.clear();
      await _loadAll();
      _toast('Account created');
    } on DioException catch (error) {
      _toast(error.response?.data?['error']?.toString() ??
          'Unable to create account');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setStatus(Map<String, dynamic> user) async {
    final nextStatus = user['status'] == 'disabled' ? 'active' : 'disabled';
    await _api.patch('/admin/users/${user['id']}/status',
        data: {'status': nextStatus});
    await _loadAll();
    _toast(nextStatus == 'disabled' ? 'Account disabled' : 'Account enabled');
  }

  Future<void> _resetPassword() async {
    final id = _selectedUserId;
    if (id == null || _resetController.text.length < 8) {
      _toast('Select a user and enter at least 8 characters');
      return;
    }
    await _api.post('/admin/users/$id/reset-password',
        data: {'password': _resetController.text});
    await _loadLogs();
    _toast('Password reset complete');
  }

  Future<void> _exportCsv() async {
    final csv = await _api.downloadText('/admin/export/users.csv');
    await Clipboard.setData(ClipboardData(text: csv));
    _toast('CSV copied to clipboard for Excel');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final counts =
        Map<String, dynamic>.from(_dashboard['counts'] as Map? ?? {});
    final storage =
        Map<String, dynamic>.from(_dashboard['storage'] as Map? ?? {});
    final classes =
        List<Map<String, dynamic>>.from(_dashboard['classes'] as List? ?? []);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardGrid(
          minItemWidth: 180,
          children: [
            KPIStatCard(
              label: 'Users',
              value: '${counts['users'] ?? 0}',
              icon: Icons.manage_accounts_outlined,
              color: scheme.primary,
              detail: '${counts['active'] ?? 0} active',
              isLoading: _loading,
            ),
            KPIStatCard(
              label: 'Students',
              value: '${counts['studentRecords'] ?? counts['students'] ?? 0}',
              icon: Icons.school_outlined,
              color: Colors.teal,
              detail: 'Admission records',
              isLoading: _loading,
            ),
            KPIStatCard(
              label: 'Disabled',
              value: '${counts['disabled'] ?? 0}',
              icon: Icons.block_outlined,
              color: Colors.deepOrange,
              detail: 'Access blocked',
              isLoading: _loading,
            ),
            KPIStatCard(
              label: 'Storage',
              value: storage['pretty']?.toString() ?? '0 bytes',
              icon: Icons.storage_outlined,
              color: Colors.indigo,
              detail: '${counts['auditLogs'] ?? 0} audit records',
              isLoading: _loading,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final form = _CreateUserForm(
              formKey: _formKey,
              role: _createRole,
              onRoleChanged: (value) => setState(() => _createRole = value),
              emailController: _emailController,
              passwordController: _passwordController,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              phoneController: _phoneController,
              gradeController: _gradeController,
              sectionController: _sectionController,
              rollController: _rollController,
              parents: _parents,
              parentUserId: _parentUserId,
              onParentChanged: (value) => setState(() => _parentUserId = value),
              onSubmit: _createUser,
              saving: _saving,
            );
            final list = _UserDirectory(
              users: _users,
              classes: classes,
              searchController: _searchController,
              role: _filterRole,
              status: _status,
              classFilter: _classFilter,
              selectedUserId: _selectedUserId,
              onRoleChanged: (value) async {
                setState(() => _filterRole = value);
                await _loadUsers();
              },
              onStatusChanged: (value) async {
                setState(() => _status = value);
                await _loadUsers();
              },
              onClassChanged: (value) async {
                setState(() => _classFilter = value);
                await _loadUsers();
              },
              onSearch: _loadUsers,
              onSelectUser: (value) => setState(() => _selectedUserId = value),
              onToggleStatus: _setStatus,
              resetController: _resetController,
              onResetPassword: _resetPassword,
              onExportCsv: _exportCsv,
            );

            if (!wide) {
              return Column(children: [
                form,
                const SizedBox(height: AppSpacing.md),
                list
              ]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: form),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: list),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _AuditLogPanel(logs: _logs, onRefresh: _loadLogs),
      ],
    );
  }
}

class _CreateUserForm extends StatelessWidget {
  const _CreateUserForm({
    required this.formKey,
    required this.role,
    required this.onRoleChanged,
    required this.emailController,
    required this.passwordController,
    required this.firstNameController,
    required this.lastNameController,
    required this.phoneController,
    required this.gradeController,
    required this.sectionController,
    required this.rollController,
    required this.parents,
    required this.parentUserId,
    required this.onParentChanged,
    required this.onSubmit,
    required this.saving,
  });

  final GlobalKey<FormState> formKey;
  final String role;
  final ValueChanged<String> onRoleChanged;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController phoneController;
  final TextEditingController gradeController;
  final TextEditingController sectionController;
  final TextEditingController rollController;
  final List<Map<String, dynamic>> parents;
  final int? parentUserId;
  final ValueChanged<int?> onParentChanged;
  final VoidCallback onSubmit;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create account',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                DropdownMenuItem(value: 'parent', child: Text('Parent')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                if (value != null) onRoleChanged(value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Initial password'),
              obscureText: true,
              validator: (value) => value == null || value.length < 8
                  ? 'Minimum 8 characters'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                    child: TextFormField(
                        controller: firstNameController,
                        decoration:
                            const InputDecoration(labelText: 'First name'))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: TextFormField(
                        controller: lastNameController,
                        decoration:
                            const InputDecoration(labelText: 'Last name'))),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone')),
            if (role == 'student') ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: gradeController,
                          decoration:
                              const InputDecoration(labelText: 'Class'))),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: TextFormField(
                          controller: sectionController,
                          decoration:
                              const InputDecoration(labelText: 'Division'))),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: TextFormField(
                          controller: rollController,
                          decoration:
                              const InputDecoration(labelText: 'Roll no.'))),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<int>(
                initialValue: parentUserId,
                decoration: const InputDecoration(labelText: 'Parent'),
                items: [
                  for (final parent in parents)
                    DropdownMenuItem(
                      value: parent['id'] as int,
                      child: Text(parent['email']?.toString() ??
                          'Parent ${parent['id']}'),
                    ),
                ],
                onChanged: onParentChanged,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: role == 'student' ? 'Admit student' : 'Create user',
              icon: role == 'student' ? Icons.person_add_alt_1 : Icons.add,
              isLoading: saving,
              onPressed: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDirectory extends StatelessWidget {
  const _UserDirectory({
    required this.users,
    required this.classes,
    required this.searchController,
    required this.role,
    required this.status,
    required this.classFilter,
    required this.selectedUserId,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onClassChanged,
    required this.onSearch,
    required this.onSelectUser,
    required this.onToggleStatus,
    required this.resetController,
    required this.onResetPassword,
    required this.onExportCsv,
  });

  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> classes;
  final TextEditingController searchController;
  final String role;
  final String status;
  final String classFilter;
  final int? selectedUserId;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onClassChanged;
  final VoidCallback onSearch;
  final ValueChanged<int?> onSelectUser;
  final ValueChanged<Map<String, dynamic>> onToggleStatus;
  final TextEditingController resetController;
  final VoidCallback onResetPassword;
  final VoidCallback onExportCsv;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search users'),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              _FilterMenu(
                label: 'Role',
                value: role,
                values: const ['all', 'student', 'teacher', 'parent', 'admin'],
                onChanged: onRoleChanged,
              ),
              _FilterMenu(
                label: 'Status',
                value: status,
                values: const ['all', 'active', 'disabled'],
                onChanged: onStatusChanged,
              ),
              _FilterMenu(
                label: 'Class',
                value: classFilter,
                values: [
                  'all',
                  ...classes.map((row) => row['class_name'].toString())
                ],
                onChanged: onClassChanged,
              ),
              IconButton.filledTonal(
                tooltip: 'Apply search',
                onPressed: onSearch,
                icon: const Icon(Icons.tune),
              ),
              IconButton.filledTonal(
                tooltip: 'Export CSV for Excel',
                onPressed: onExportCsv,
                icon: const Icon(Icons.download_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Class')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: [
                for (final user in users)
                  DataRow(
                    selected: selectedUserId == user['id'],
                    onSelectChanged: (_) => onSelectUser(user['id'] as int?),
                    cells: [
                      DataCell(Text(user['email']?.toString() ?? '')),
                      DataCell(Text(user['role']?.toString() ?? '')),
                      DataCell(Text(
                          (user['student'] as Map?)?['className']?.toString() ??
                              '-')),
                      DataCell(Text(user['status']?.toString() ?? 'active')),
                      DataCell(
                        IconButton(
                          tooltip: user['status'] == 'disabled'
                              ? 'Enable account'
                              : 'Disable account',
                          onPressed: () => onToggleStatus(user),
                          icon: Icon(user['status'] == 'disabled'
                              ? Icons.lock_open
                              : Icons.block),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: resetController,
                  decoration: const InputDecoration(labelText: 'New password'),
                  obscureText: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: 'Reset',
                icon: Icons.key,
                onPressed: selectedUserId == null ? null : onResetPassword,
                size: AppButtonSize.sm,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String>(
        initialValue: values.contains(value) ? value : 'all',
        decoration: InputDecoration(labelText: label),
        items: [
          for (final item in values)
            DropdownMenuItem(
                value: item, child: Text(item == 'all' ? 'All' : item)),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _AuditLogPanel extends StatelessWidget {
  const _AuditLogPanel({required this.logs, required this.onRefresh});

  final List<Map<String, dynamic>> logs;
  final VoidCallback onRefresh;

  String _time(String? raw) {
    final parsed = DateTime.tryParse(raw ?? '');
    if (parsed == null) return 'Now';
    final local = parsed.toLocal();
    return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Audit logs',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800))),
              IconButton.filledTonal(
                  tooltip: 'Refresh logs',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final log in logs.take(8))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: const Icon(Icons.history, size: 18),
              ),
              title: Text(log['detail']?.toString() ??
                  log['action']?.toString() ??
                  'Audit event'),
              subtitle: Text(
                  '${log['category']} • ${log['actor_email'] ?? 'system'} • ${_time(log['created_at']?.toString())}'),
            ),
        ],
      ),
    );
  }
}
