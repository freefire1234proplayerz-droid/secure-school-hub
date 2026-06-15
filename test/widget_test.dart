import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:secure_school_hub/providers/locale_provider.dart';
import 'package:secure_school_hub/services/auth_service.dart';
import 'package:secure_school_hub/services/local_db.dart';
import 'package:secure_school_hub/theme/app_theme.dart';
import 'package:secure_school_hub/widgets/attendance/qr_scanner_overlay.dart';
import 'package:secure_school_hub/widgets/shell/app_shell.dart';

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = Directory.systemTemp.createTempSync('secure_school_hub_test_');
    Hive.init(hiveDir.path);
    await LocalDb.init();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
  });

  testWidgets('AppShell keeps safe constraints during collapse and resize',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(1200, 820));
    await _pumpShell(tester);

    for (var i = 0; i < 6; i++) {
      await _tapSidebarToggle(tester);
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();

    for (final size in const [
      Size(980, 760),
      Size(620, 760),
      Size(390, 760),
      Size(1440, 900),
      Size(1024, 720),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('FAB quick actions remain usable after sidebar collapse',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(1280, 820));
    await _pumpShell(tester);

    await _tapSidebarToggle(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bolt_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Send announcement'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Notification overlay survives shell breakpoint transitions',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(1180, 820));
    await _pumpShell(tester);
    await _tapSidebarToggle(tester);
    await tester.pumpAndSettle();

    await tester.binding.setSurfaceSize(const Size(760, 760));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Door alert'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Notification overlay does not block FAB interactions',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(1280, 820));
    await _pumpShell(tester);

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Door alert'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bolt_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Send announcement'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Overlay and quick action spam leaves interactions alive',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var actionCount = 0;
    await tester.binding.setSurfaceSize(const Size(1180, 820));
    await _pumpShell(
      tester,
      onQuickAction: () => actionCount++,
    );

    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pumpAndSettle();

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byIcon(Icons.bolt_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send announcement').last);
      await tester.pumpAndSettle();
    }

    expect(actionCount, 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Scanner overlay never intercepts underlying controls',
      (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Stack(
            children: [
              Center(
                child: ElevatedButton(
                  onPressed: () => tapped = true,
                  child: const Text('Underlying action'),
                ),
              ),
              const QRScannerOverlay(
                state: QRScannerState.scanning,
                message: 'Scanning',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Underlying action'));
    await tester.pump();

    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile menu opens and closes repeatedly without stale overlays',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(1280, 820));
    await _pumpShell(tester, onLogout: () {});

    for (var i = 0; i < 12; i++) {
      await tester.tap(find.byTooltip('Account'));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Sign out'), findsOneWidget);

      await tester.tap(find.byTooltip('Account'));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Sign out'), findsNothing);
    }

    await tester.tap(find.byIcon(Icons.bolt_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Quick actions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile menu and notification overlay are mutually exclusive',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(1280, 820));
    await _pumpShell(tester, onLogout: () {});

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Door alert'), findsOneWidget);

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Door alert'), findsNothing);
    expect(find.text('Sign out'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsNothing);
    expect(find.text('Door alert'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile logout shows confirmation and invokes logout once',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var logoutCount = 0;
    await tester.binding.setSurfaceSize(const Size(1280, 820));
    await _pumpShell(tester, onLogout: () => logoutCount++);

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Sign out?'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(logoutCount, 1);
    expect(find.text('Sign out?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpShell(
  WidgetTester tester, {
  VoidCallback? onQuickAction,
  VoidCallback? onLogout,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: AppShell(
          title: 'SecureSchoolHub Operations',
          navItems: _navItems,
          selectedIndex: 0,
          onNavSelected: (_) {},
          onLogout: onLogout,
          notifications: const [
            ShellNotification(
              id: 'door-alert',
              title: 'Door alert',
              body: 'Main gate opened',
              icon: Icons.security_rounded,
              color: Colors.red,
            ),
          ],
          quickActions: [
            ShellQuickAction(
              label: 'Send announcement',
              icon: Icons.campaign_rounded,
              onTap: onQuickAction ?? () {},
            ),
          ],
          body: const SizedBox(
            height: 1600,
            child: Column(
              children: [
                Text('Dashboard body'),
                SizedBox(height: 1200),
                Text('End of dashboard'),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapSidebarToggle(WidgetTester tester) async {
  final collapse = find.byTooltip('Collapse sidebar');
  final expand = find.byTooltip('Expand sidebar');
  final target = collapse.evaluate().isNotEmpty ? collapse : expand;

  expect(target, findsOneWidget);
  await tester.tap(target);
}

const _navItems = [
  ShellNavItem(
    id: 'overview',
    label: 'Overview',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    shortcut: '1',
  ),
  ShellNavItem(
    id: 'analytics',
    label: 'Analytics',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
    shortcut: '2',
  ),
  ShellNavItem(
    id: 'actions',
    label: 'Actions',
    icon: Icons.bolt_outlined,
    selectedIcon: Icons.bolt_rounded,
    shortcut: '3',
  ),
  ShellNavItem(
    id: 'security',
    label: 'Security',
    icon: Icons.shield_outlined,
    selectedIcon: Icons.shield_rounded,
    shortcut: '4',
  ),
  ShellNavItem(
    id: 'messages',
    label: 'Messages',
    icon: Icons.chat_outlined,
    selectedIcon: Icons.chat_rounded,
    shortcut: '5',
  ),
];
