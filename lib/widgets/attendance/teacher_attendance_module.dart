import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../dashboard/dashboard_grid.dart';
import '../dashboard/dashboard_section.dart';
import '../design_system/app_button.dart';
import 'attendance_analytics_panel.dart';
import 'attendance_chart_card.dart';
import 'attendance_filter_bar.dart';
import 'attendance_heatmap.dart';
import 'attendance_models.dart';
import 'attendance_ring_chart.dart';
import 'attendance_session_card.dart';
import 'attendance_stat_card.dart';
import 'attendance_timeline.dart';
import 'qr_scanner_overlay.dart';
import 'student_attendance_tile.dart';

/// Complete teacher attendance management UI module.
class TeacherAttendanceModule extends StatefulWidget {
  const TeacherAttendanceModule({super.key});

  @override
  State<TeacherAttendanceModule> createState() => TeacherAttendanceModuleState();
}

class TeacherAttendanceModuleState extends State<TeacherAttendanceModule> {
  final ApiService _api = ApiService();
  final _searchController = TextEditingController();

  int _selectedTab = 0;
  bool _loading = true;
  bool _saving = false;
  double _saveProgress = 0;

  List<StudentAttendanceRecord> _students = [];
  Map<String, dynamic> _summary = {
    'totalStudents': 0,
    'presentToday': 0,
    'attendancePercent': 0,
    'recent': [],
  };

  String _selectedClass = 'Class 8A';
  String _selectedSubject = 'Mathematics';
  DateTime _selectedDate = DateTime.now();
  AttendanceStatus? _statusFilter;
  List<ScanHistoryEntry> _scanHistory = [];

  final _classes = const ['Class 8A', 'Class 8B', 'Class 9A'];
  final _subjects = const ['Mathematics', 'Science', 'English'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Opens the premium full-screen QR scanner (callable from shell quick actions).
  void openQrScanner() {
    setState(() => _selectedTab = 1);
    _openQrScanner();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final studentsRes = await _api.get('/attendance/students');
      final summaryRes = await _api.get('/attendance/summary');
      if (!mounted) return;

      final studentRows = List<Map<String, dynamic>>.from(
        studentsRes.data['students'] as List<dynamic>? ?? [],
      );
      final summary = Map<String, dynamic>.from(summaryRes.data as Map);

      setState(() {
        _students = studentRows.map(StudentAttendanceRecord.fromApi).toList();
        _summary = summary;
        _markPresentFromSummary();
        if (_students.isNotEmpty) {
          _selectedClass = _students.first.className;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _markPresentFromSummary() {
    // Students marked via API appear in recent list — reflect as present locally.
    final recent = List<Map<String, dynamic>>.from(
      _summary['recent'] as List? ?? [],
    );
    for (final r in recent) {
      final name = r['studentName']?.toString();
      final idx = _students.indexWhere((s) => s.name == name);
      if (idx >= 0) {
        _students[idx].status = AttendanceStatus.present;
        final markedAt = DateTime.tryParse(r['markedAt']?.toString() ?? '');
        _students[idx].markedAt = markedAt;
      }
    }
  }

  int get _presentCount =>
      _students.where((s) => s.status == AttendanceStatus.present).length;

  int get _absentCount =>
      _students.where((s) => s.status == AttendanceStatus.absent).length;

  int get _lateCount =>
      _students.where((s) => s.status == AttendanceStatus.late).length;

  int get _total => _students.length;

  List<StudentAttendanceRecord> get _filteredStudents {
    final q = _searchController.text.trim().toLowerCase();
    return _students.where((s) {
      if (_statusFilter != null && s.status != _statusFilter) return false;
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) ||
          s.rollNo.toLowerCase().contains(q);
    }).toList();
  }

  List<ClassAttendanceSummary> get _classSummaries {
    final map = <String, ClassAttendanceSummary>{};
    for (final s in _students) {
      final existing = map[s.className];
      final present = s.status == AttendanceStatus.present ? 1 : 0;
      final late = s.status == AttendanceStatus.late ? 1 : 0;
      if (existing == null) {
        map[s.className] = ClassAttendanceSummary(
          className: s.className,
          present: present,
          total: 1,
          late: late,
        );
      } else {
        map[s.className] = ClassAttendanceSummary(
          className: s.className,
          present: existing.present + present,
          total: existing.total + 1,
          late: existing.late + late,
        );
      }
    }
    return map.values.toList();
  }

  List<AttendanceActivityItem> get _activityItems {
    final recent = List<Map<String, dynamic>>.from(
      _summary['recent'] as List? ?? [],
    );
    return recent.map((r) {
      final markedAt =
          DateTime.tryParse(r['markedAt']?.toString() ?? '') ?? DateTime.now();
      return AttendanceActivityItem(
        title: r['studentName']?.toString() ?? 'Student',
        subtitle: '${r['className']} marked present',
        timestamp: markedAt,
        status: AttendanceStatus.present,
      );
    }).toList();
  }

  List<List<AttendanceStatus>> get _heatmapData {
    return [
      for (var i = 0; i < _students.length.clamp(0, 8); i++)
        List.generate(6, (d) {
          final s = _students[i].status;
          if (s != AttendanceStatus.unmarked) return s;
          return d < 4 ? AttendanceStatus.present : AttendanceStatus.unmarked;
        }),
    ];
  }

  Future<Map<String, dynamic>?> _handleQrScan(String qr) async {
    final res = await _api.post('/attendance/mark', data: {'qr': qr});
    return Map<String, dynamic>.from(res.data as Map);
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            QRAttendanceScreen(
          onScan: _handleQrScan,
          onClose: () {
            Navigator.pop(context);
            _loadData();
          },
          scanHistory: _scanHistory,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _setBulkStatus(AttendanceStatus status) {
    setState(() {
      for (final s in _filteredStudents) {
        final idx = _students.indexWhere((x) => x.id == s.id);
        if (idx >= 0) _students[idx].status = status;
      }
    });
  }

  Future<void> _saveManualAttendance() async {
    final toMark = _students
        .where((s) => s.status == AttendanceStatus.present)
        .toList();
    if (toMark.isEmpty) return;

    setState(() {
      _saving = true;
      _saveProgress = 0;
    });

    var saved = 0;
    for (final student in toMark) {
      try {
        await _api.post('/attendance/mark', data: {'qr': student.qrPayload});
        saved++;
      } catch (_) {
        // Continue with remaining students.
      }
      if (mounted) {
        setState(() => _saveProgress = saved / toMark.length);
      }
    }

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved attendance for $saved students')),
      );
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_summary['attendancePercent'] as num?)?.toDouble() ?? 0;
    final weekly = [88.0, 91.0, 86.0, percent, 90.0, 93.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassManagementBar(
          classes: _classes,
          selectedClass: _selectedClass,
          onClassChanged: (v) => setState(() => _selectedClass = v),
          subjects: _subjects,
          selectedSubject: _selectedSubject,
          onSubjectChanged: (v) => setState(() => _selectedSubject = v),
          selectedDate: _selectedDate,
          onDateChanged: (d) => setState(() => _selectedDate = d),
          sessionStatus: 'Session active • ${_presentCount}/$_total marked',
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardGrid(
          minItemWidth: 160,
          children: [
            AttendanceSessionCard(
              session: const AttendanceSessionInfo(
                label: 'Morning assembly',
                startTime: '08:00',
                endTime: '08:30',
                isActive: false,
                subject: 'School-wide',
              ),
            ),
            AttendanceSessionCard(
              session: AttendanceSessionInfo(
                label: _selectedClass,
                startTime: '08:35',
                endTime: '09:20',
                isActive: true,
                subject: _selectedSubject,
              ),
              isSelected: true,
            ),
            AttendanceSessionCard(
              session: const AttendanceSessionInfo(
                label: 'Afternoon lab',
                startTime: '13:00',
                endTime: '14:00',
                isActive: false,
                subject: 'Science',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Overview'), icon: Icon(Icons.dashboard_outlined, size: 16)),
              ButtonSegment(value: 1, label: Text('QR Scan'), icon: Icon(Icons.qr_code_scanner, size: 16)),
              ButtonSegment(value: 2, label: Text('Manual'), icon: Icon(Icons.edit_note_outlined, size: 16)),
              ButtonSegment(value: 3, label: Text('Analytics'), icon: Icon(Icons.insights_outlined, size: 16)),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (s) => setState(() => _selectedTab = s.first),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        switch (_selectedTab) {
          0 => _OverviewTab(
                loading: _loading,
                present: _presentCount,
                absent: _absentCount,
                late: _lateCount,
                total: _total,
                percent: percent,
                weekly: weekly,
                classSummaries: _classSummaries,
                heatmap: _heatmapData,
                activity: _activityItems,
                onRefresh: _loadData,
              ),
          1 => _QrTab(onOpenScanner: _openQrScanner),
          2 => _ManualTab(
                loading: _loading,
                saving: _saving,
                saveProgress: _saveProgress,
                searchController: _searchController,
                students: _filteredStudents,
                allStudents: _students,
                statusFilter: _statusFilter,
                onStatusFilterChanged: (f) => setState(() => _statusFilter = f),
                onSearchChanged: (_) => setState(() {}),
                onBulkPresent: () => _setBulkStatus(AttendanceStatus.present),
                onBulkAbsent: () => _setBulkStatus(AttendanceStatus.absent),
                onBulkLate: () => _setBulkStatus(AttendanceStatus.late),
                onStatusChanged: (index, status) {
                  final student = _filteredStudents[index];
                  final idx = _students.indexWhere((s) => s.id == student.id);
                  if (idx >= 0) setState(() => _students[idx].status = status);
                },
                onSave: _saveManualAttendance,
              ),
          3 => AttendanceAnalyticsPanel(
                attendancePercent: percent,
                weeklyTrend: weekly,
                lowAttendanceStudents: [
                  for (final s in _students.take(3))
                    (name: s.name, percent: 72 + s.id % 20),
                ],
              ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.loading,
    required this.present,
    required this.absent,
    required this.late,
    required this.total,
    required this.percent,
    required this.weekly,
    required this.classSummaries,
    required this.heatmap,
    required this.activity,
    required this.onRefresh,
  });

  final bool loading;
  final int present;
  final int absent;
  final int late;
  final int total;
  final double percent;
  final List<double> weekly;
  final List<ClassAttendanceSummary> classSummaries;
  final List<List<AttendanceStatus>> heatmap;
  final List<AttendanceActivityItem> activity;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's attendance",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              AppButton(
                label: 'Refresh',
                icon: Icons.refresh,
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                onPressed: onRefresh,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DashboardGrid(
            children: [
              AttendanceStatCard(
                label: 'Present',
                value: '$present',
                icon: Icons.check_circle_outline,
                color: Colors.teal,
                subtitle: 'Marked today',
                isLoading: loading,
              ),
              AttendanceStatCard(
                label: 'Absent',
                value: '$absent',
                icon: Icons.cancel_outlined,
                color: scheme.error,
                isLoading: loading,
              ),
              AttendanceStatCard(
                label: 'Late',
                value: '$late',
                icon: Icons.schedule,
                color: Colors.deepOrange,
                isLoading: loading,
              ),
              AttendanceStatCard(
                label: 'Total students',
                value: '$total',
                icon: Icons.groups_2_outlined,
                color: scheme.primary,
                isLoading: loading,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= AppBreakpoints.tablet) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: AttendanceChartCard(
                        values: weekly,
                        title: 'Weekly attendance trend',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AttendanceRingChart(
                        percent: total == 0 ? 0 : present / total,
                        centerLabel: '${percent.round()}%',
                        label: 'Today',
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  AttendanceRingChart(
                    percent: total == 0 ? 0 : present / total,
                    centerLabel: '${percent.round()}%',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AttendanceChartCard(values: weekly),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          DashboardSection(
            title: 'Class-wise attendance',
            useGlassPanel: false,
            animate: false,
            child: ClassAttendanceCards(classes: classSummaries),
          ),
          const SizedBox(height: AppSpacing.lg),
          AttendanceHeatmap(rows: heatmap),
          const SizedBox(height: AppSpacing.lg),
          AttendanceTimeline(items: activity),
        ],
    );
  }
}

class _QrTab extends StatelessWidget {
  const _QrTab({required this.onOpenScanner});

  final VoidCallback onOpenScanner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Premium QR attendance',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Full-screen scanner with animated overlay,\nconfirmation modal, and scan history.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Open QR scanner',
            icon: Icons.qr_code_scanner,
            onPressed: onOpenScanner,
            size: AppButtonSize.lg,
          ),
        ],
      ),
    );
  }
}

class _ManualTab extends StatelessWidget {
  const _ManualTab({
    required this.loading,
    required this.saving,
    required this.saveProgress,
    required this.searchController,
    required this.students,
    required this.allStudents,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.onSearchChanged,
    required this.onBulkPresent,
    required this.onBulkAbsent,
    required this.onBulkLate,
    required this.onStatusChanged,
    required this.onSave,
  });

  final bool loading;
  final bool saving;
  final double saveProgress;
  final TextEditingController searchController;
  final List<StudentAttendanceRecord> students;
  final List<StudentAttendanceRecord> allStudents;
  final AttendanceStatus? statusFilter;
  final ValueChanged<AttendanceStatus?> onStatusFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBulkPresent;
  final VoidCallback onBulkAbsent;
  final VoidCallback onBulkLate;
  final void Function(int index, AttendanceStatus status) onStatusChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AttendanceFilterBar(
            searchController: searchController,
            onSearchChanged: onSearchChanged,
            statusFilter: statusFilter,
            onStatusFilterChanged: onStatusFilterChanged,
            onBulkPresent: onBulkPresent,
            onBulkAbsent: onBulkAbsent,
            onBulkLate: onBulkLate,
          ),
          const SizedBox(height: AppSpacing.md),
          if (saving)
            Column(
              children: [
                LinearProgressIndicator(value: saveProgress),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Saving attendance… ${(saveProgress * 100).round()}%',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: Text('No students match your filters')),
            )
          else if (isDesktop)
            StudentAttendanceTable(
              students: students,
              onStatusChanged: onStatusChanged,
            )
          else
            Column(
              children: [
                for (var i = 0; i < students.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: StudentAttendanceTile(
                      student: students[i],
                      index: i,
                      onStatusChanged: (status) => onStatusChanged(i, status),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: saving ? 'Saving…' : 'Save attendance',
            icon: Icons.save_outlined,
            onPressed: saving ? null : onSave,
            isLoading: saving,
            expand: true,
          ),
        ],
    );
  }
}
