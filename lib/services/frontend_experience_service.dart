import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum PendingActionType {
  attendance,
  noticeDraft,
  chatDraft,
  upload,
  preference,
}

enum DashboardDensity { compact, comfortable }

class PendingAction {
  const PendingAction({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.payload = const {},
    this.attempts = 0,
    this.synced = false,
  });

  final String id;
  final PendingActionType type;
  final String title;
  final DateTime createdAt;
  final Map<String, Object?> payload;
  final int attempts;
  final bool synced;

  PendingAction copyWith({
    int? attempts,
    bool? synced,
  }) {
    return PendingAction(
      id: id,
      type: type,
      title: title,
      createdAt: createdAt,
      payload: payload,
      attempts: attempts ?? this.attempts,
      synced: synced ?? this.synced,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
        'attempts': attempts,
        'synced': synced,
      };

  static PendingAction fromJson(Map<dynamic, dynamic> json) {
    return PendingAction(
      id: json['id']?.toString() ?? '',
      type: PendingActionType.values.firstWhere(
        (type) => type.name == json['type']?.toString(),
        orElse: () => PendingActionType.preference,
      ),
      title: json['title']?.toString() ?? 'Pending action',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      payload: Map<String, Object?>.from(json['payload'] as Map? ?? const {}),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      synced: json['synced'] == true,
    );
  }
}

class ActivityPulse {
  const ActivityPulse({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final DateTime createdAt;
}

class UserExperiencePreferences {
  const UserExperiencePreferences({
    this.accentColor = Colors.indigo,
    this.density = DashboardDensity.comfortable,
    this.reducedMotion = false,
    this.highContrast = false,
    this.pushBanners = true,
    this.scannerHaptics = true,
  });

  final Color accentColor;
  final DashboardDensity density;
  final bool reducedMotion;
  final bool highContrast;
  final bool pushBanners;
  final bool scannerHaptics;

  UserExperiencePreferences copyWith({
    Color? accentColor,
    DashboardDensity? density,
    bool? reducedMotion,
    bool? highContrast,
    bool? pushBanners,
    bool? scannerHaptics,
  }) {
    return UserExperiencePreferences(
      accentColor: accentColor ?? this.accentColor,
      density: density ?? this.density,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      highContrast: highContrast ?? this.highContrast,
      pushBanners: pushBanners ?? this.pushBanners,
      scannerHaptics: scannerHaptics ?? this.scannerHaptics,
    );
  }

  Map<String, Object?> toJson() => {
        'accentColor': accentColor.toARGB32(),
        'density': density.name,
        'reducedMotion': reducedMotion,
        'highContrast': highContrast,
        'pushBanners': pushBanners,
        'scannerHaptics': scannerHaptics,
      };

  static UserExperiencePreferences fromJson(Map<dynamic, dynamic> json) {
    return UserExperiencePreferences(
      accentColor: Color(
        (json['accentColor'] as num?)?.toInt() ?? Colors.indigo.toARGB32(),
      ),
      density: DashboardDensity.values.firstWhere(
        (density) => density.name == json['density']?.toString(),
        orElse: () => DashboardDensity.comfortable,
      ),
      reducedMotion: json['reducedMotion'] == true,
      highContrast: json['highContrast'] == true,
      pushBanners: json['pushBanners'] != false,
      scannerHaptics: json['scannerHaptics'] != false,
    );
  }
}

class AppExperienceSnapshot {
  const AppExperienceSnapshot({
    required this.online,
    required this.syncing,
    required this.syncProgress,
    required this.pendingActions,
    required this.activities,
    required this.preferences,
    required this.lastHydratedAt,
    required this.liveTick,
  });

  final bool online;
  final bool syncing;
  final double syncProgress;
  final List<PendingAction> pendingActions;
  final List<ActivityPulse> activities;
  final UserExperiencePreferences preferences;
  final DateTime? lastHydratedAt;
  final int liveTick;

  int get pendingCount => pendingActions.where((a) => !a.synced).length;

  AppExperienceSnapshot copyWith({
    bool? online,
    bool? syncing,
    double? syncProgress,
    List<PendingAction>? pendingActions,
    List<ActivityPulse>? activities,
    UserExperiencePreferences? preferences,
    DateTime? lastHydratedAt,
    int? liveTick,
  }) {
    return AppExperienceSnapshot(
      online: online ?? this.online,
      syncing: syncing ?? this.syncing,
      syncProgress: syncProgress ?? this.syncProgress,
      pendingActions: pendingActions ?? this.pendingActions,
      activities: activities ?? this.activities,
      preferences: preferences ?? this.preferences,
      lastHydratedAt: lastHydratedAt ?? this.lastHydratedAt,
      liveTick: liveTick ?? this.liveTick,
    );
  }

  static AppExperienceSnapshot initial() => AppExperienceSnapshot(
        online: true,
        syncing: false,
        syncProgress: 1,
        pendingActions: const [],
        activities: [
          ActivityPulse(
            title: 'Live workspace started',
            detail: 'Offline queue and local intelligence are ready.',
            icon: Icons.bolt_rounded,
            color: Colors.teal,
            createdAt: DateTime.now(),
          ),
        ],
        preferences: const UserExperiencePreferences(),
        lastHydratedAt: DateTime.now(),
        liveTick: 0,
      );
}

class FrontendExperienceService {
  FrontendExperienceService._();

  static final FrontendExperienceService instance =
      FrontendExperienceService._();

  final ValueNotifier<AppExperienceSnapshot> snapshot =
      ValueNotifier(AppExperienceSnapshot.initial());

  Box<dynamic>? _box;
  Timer? _heartbeat;
  bool _initialized = false;
  int _syncRun = 0;
  final _random = math.Random(7);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _hydrate();
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 5), (_) {
      final current = snapshot.value;
      final nextActivity = _mockActivity(current.liveTick);
      final updated = [
        nextActivity,
        ...current.activities,
      ].take(8).toList();
      snapshot.value = current.copyWith(
        online: true,
        activities: updated,
        liveTick: current.liveTick + 1,
      );
      _persistSoft();
      if (snapshot.value.pendingCount > 0) {
        unawaited(syncPendingActions());
      }
    });
  }

  void pause() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _initialized = false;
  }

  Future<void> _hydrate() async {
    try {
      _box = await Hive.openBox<dynamic>('frontend_experience_v1');
      final queueRows = (_box?.get('pendingActions') as List?) ?? const [];
      final prefRow = _box?.get('preferences');
      final pending = queueRows
          .whereType<Map<dynamic, dynamic>>()
          .map(PendingAction.fromJson)
          .where((action) => action.id.isNotEmpty)
          .toList();
      final preferences = prefRow is Map
          ? UserExperiencePreferences.fromJson(prefRow)
          : snapshot.value.preferences;
      snapshot.value = snapshot.value.copyWith(
        pendingActions: pending,
        preferences: preferences,
        lastHydratedAt: DateTime.now(),
      );
    } catch (_) {
      snapshot.value = snapshot.value.copyWith(lastHydratedAt: DateTime.now());
    }
  }

  Future<void> queueAction(
    PendingActionType type, {
    required String title,
    Map<String, Object?> payload = const {},
  }) async {
    final action = PendingAction(
      id: '${type.name}-${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      title: title,
      createdAt: DateTime.now(),
      payload: payload,
    );
    final current = snapshot.value;
    snapshot.value = current.copyWith(
      pendingActions: [action, ...current.pendingActions],
      activities: [
        ActivityPulse(
          title: 'Queued offline',
          detail: title,
          icon: Icons.cloud_upload_outlined,
          color: Colors.deepOrange,
          createdAt: DateTime.now(),
        ),
        ...current.activities,
      ].take(8).toList(),
    );
    await _persistSoft();
    if (snapshot.value.online) {
      unawaited(syncPendingActions());
    }
  }

  Future<void> savePreferences(UserExperiencePreferences preferences) async {
    snapshot.value = snapshot.value.copyWith(preferences: preferences);
    await _persistSoft();
    await queueAction(
      PendingActionType.preference,
      title: 'Saved dashboard preferences',
      payload: preferences.toJson(),
    );
  }

  Future<void> syncPendingActions() async {
    final run = ++_syncRun;
    final pending = snapshot.value.pendingActions
        .where((action) => !action.synced)
        .toList(growable: false);
    if (pending.isEmpty || snapshot.value.syncing) return;

    snapshot.value = snapshot.value.copyWith(syncing: true, syncProgress: 0);
    for (var i = 0; i < pending.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (run != _syncRun) return;
      final action = pending[i].copyWith(
        attempts: pending[i].attempts + 1,
        synced: true,
      );
      final all = snapshot.value.pendingActions.map((candidate) {
        return candidate.id == action.id ? action : candidate;
      }).toList();
      snapshot.value = snapshot.value.copyWith(
        pendingActions: all,
        syncProgress: (i + 1) / pending.length,
      );
    }

    final remaining = snapshot.value.pendingActions
        .where((action) => !action.synced)
        .toList(growable: false);
    snapshot.value = snapshot.value.copyWith(
      syncing: false,
      syncProgress: 1,
      pendingActions: remaining,
      activities: [
        ActivityPulse(
          title: 'Sync complete',
          detail: '${pending.length} local action(s) reconciled.',
          icon: Icons.cloud_done_outlined,
          color: Colors.teal,
          createdAt: DateTime.now(),
        ),
        ...snapshot.value.activities,
      ].take(8).toList(),
    );
    await _persistSoft();
  }

  void setConnectivityOverride(bool online) {
    final current = snapshot.value;
    snapshot.value = current.copyWith(
      online: online,
      activities: [
        ActivityPulse(
          title: online ? 'Connection restored' : 'Offline mode active',
          detail: online
              ? 'Queued actions will sync automatically.'
              : 'Attendance, notices, uploads, and drafts are saved locally.',
          icon: online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          color: online ? Colors.teal : Colors.deepOrange,
          createdAt: DateTime.now(),
        ),
        ...current.activities,
      ].take(8).toList(),
    );
    if (online) unawaited(syncPendingActions());
  }

  Future<void> _persistSoft() async {
    try {
      await _box?.put(
        'pendingActions',
        snapshot.value.pendingActions.map((a) => a.toJson()).toList(),
      );
      await _box?.put('preferences', snapshot.value.preferences.toJson());
    } catch (_) {
      // Persistence is best-effort for tests and early startup.
    }
  }

  ActivityPulse _mockActivity(int tick) {
    final items = [
      ActivityPulse(
        title: 'Attendance stream',
        detail: '${35 + _random.nextInt(8)} students verified in Class 8A.',
        icon: Icons.how_to_reg_outlined,
        color: Colors.teal,
        createdAt: DateTime.now(),
      ),
      ActivityPulse(
        title: 'Notice engagement',
        detail:
            '${72 + _random.nextInt(18)}% of families opened today\'s notice.',
        icon: Icons.campaign_outlined,
        color: Colors.indigo,
        createdAt: DateTime.now(),
      ),
      ActivityPulse(
        title: 'Risk model refreshed',
        detail: '${3 + tick % 4} students need attendance follow-up.',
        icon: Icons.insights_outlined,
        color: Colors.deepOrange,
        createdAt: DateTime.now(),
      ),
    ];
    return items[tick % items.length];
  }
}
