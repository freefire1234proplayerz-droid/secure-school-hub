import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_spacing.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../design_system/app_button.dart';
import '../design_system/glass_card.dart';
import 'attendance_models.dart';

enum QRScannerState {
  idle,
  scanning,
  success,
  failure,
  permissionDenied,
  loading
}

/// Animated scanner frame overlay with pulse animation.
class QRScannerOverlay extends StatefulWidget {
  const QRScannerOverlay({
    super.key,
    this.state = QRScannerState.scanning,
    this.message,
  });

  final QRScannerState state;
  final String? message;

  @override
  State<QRScannerOverlay> createState() => _QRScannerOverlayState();
}

class _QRScannerOverlayState extends State<QRScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final frameColor = switch (widget.state) {
      QRScannerState.success => Colors.teal,
      QRScannerState.failure => scheme.error,
      _ => scheme.primary,
    };

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _ScannerMaskPainter(
              borderRadius: 20,
              holeSize: 260,
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulse =
                    0.5 + 0.5 * math.sin(_pulseController.value * 2 * math.pi);
                return Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: frameColor.withValues(alpha: 0.85),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: frameColor.withValues(alpha: 0.25 * pulse),
                        blurRadius: 24 + 12 * pulse,
                        spreadRadius: 2 * pulse,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _CornerBracketsPainter(color: frameColor),
                  ),
                );
              },
            ),
          ),
          if (widget.state == QRScannerState.scanning)
            Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final y = _pulseController.value * 240;
                    return Stack(
                      children: [
                        Positioned(
                          top: y,
                          left: 16,
                          right: 16,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  scheme.primary,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          if (widget.state == QRScannerState.success)
            const Center(
              child: _ResultBurst(icon: Icons.check_circle, color: Colors.teal),
            ),
          if (widget.state == QRScannerState.failure)
            Center(
              child: _ResultBurst(
                icon: Icons.error_outline,
                color: scheme.error,
              ),
            ),
          if (widget.message != null)
            Positioned(
              bottom: 120,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: GlassCard(
                child: Text(
                  widget.message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultBurst extends StatefulWidget {
  const _ResultBurst({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_ResultBurst> createState() => _ResultBurstState();
}

class _ResultBurstState extends State<_ResultBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale:
          CurvedAnimation(parent: _controller, curve: AppAnimations.emphasized),
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, size: 52, color: widget.color),
      ),
    );
  }
}

class _ScannerMaskPainter extends CustomPainter {
  _ScannerMaskPainter({required this.borderRadius, required this.holeSize});

  final double borderRadius;
  final double holeSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final holeRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: holeSize,
      height: holeSize,
    );
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
          RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerBracketsPainter extends CustomPainter {
  _CornerBracketsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    const inset = 8.0;

    void corner(Offset origin, bool flipX, bool flipY) {
      final dx = flipX ? -1.0 : 1.0;
      final dy = flipY ? -1.0 : 1.0;
      canvas.drawLine(origin, origin + Offset(len * dx, 0), paint);
      canvas.drawLine(origin, origin + Offset(0, len * dy), paint);
    }

    corner(const Offset(inset, inset), false, false);
    corner(Offset(size.width - inset, inset), true, false);
    corner(Offset(inset, size.height - inset), false, true);
    corner(Offset(size.width - inset, size.height - inset), true, true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full-screen premium QR attendance workflow.
class QRAttendanceScreen extends StatefulWidget {
  const QRAttendanceScreen({
    super.key,
    required this.onScan,
    required this.onClose,
    this.scanHistory = const [],
  });

  final Future<Map<String, dynamic>?> Function(String qr) onScan;
  final VoidCallback onClose;
  final List<ScanHistoryEntry> scanHistory;

  @override
  State<QRAttendanceScreen> createState() => _QRAttendanceScreenState();
}

class _QRAttendanceScreenState extends State<QRAttendanceScreen>
    with WidgetsBindingObserver {
  static const _scanCooldown = Duration(milliseconds: 1800);

  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.normal,
    detectionTimeoutMs: 450,
  );
  QRScannerState _state = QRScannerState.scanning;
  String? _message;
  Map<String, dynamic>? _previewStudent;
  bool _showHistory = false;
  bool _processing = false;
  bool _cameraStarting = true;
  bool _cameraReady = false;
  bool _cameraTransitioning = false;
  MobileScannerException? _cameraError;
  String? _lastScan;
  DateTime _lastScanAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _cooldownUntil = DateTime.fromMillisecondsSinceEpoch(0);
  List<ScanHistoryEntry> _history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _history = List.from(widget.scanHistory);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startCamera();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _startCamera();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _stopCamera();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (!mounted || _cameraTransitioning || _cameraReady) return;
    setState(() {
      _cameraStarting = true;
      _cameraError = null;
      _state = QRScannerState.scanning;
      _message = 'Requesting camera access…';
    });

    try {
      final args = await _controller.start();
      if (!mounted) return;
      setState(() {
        _cameraReady = args != null;
        _cameraStarting = false;
        _cameraError = null;
        _message = args == null ? 'Camera is still starting…' : null;
      });
    } on MobileScannerException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraReady = false;
        _cameraStarting = false;
        _cameraError = error;
        _state = error.errorCode == MobileScannerErrorCode.permissionDenied
            ? QRScannerState.permissionDenied
            : QRScannerState.failure;
        _message = _cameraErrorMessage(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraReady = false;
        _cameraStarting = false;
        _state = QRScannerState.failure;
        _message = 'Camera could not be started. Please try again.';
      });
    }
  }

  Future<void> _stopCamera() async {
    if (!_cameraReady && !_controller.isStarting) return;
    try {
      await _controller.stop();
    } catch (_) {
      // The native camera can already be gone during fast route transitions.
    }
    if (!mounted) return;
    setState(() {
      _cameraReady = false;
      _cameraStarting = false;
    });
  }

  Future<void> _retryCamera() async {
    await _stopCamera();
    if (!mounted) return;
    await _startCamera();
  }

  Future<void> _toggleTorch() async {
    if (_cameraTransitioning) return;
    try {
      await _controller.toggleTorch();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = QRScannerState.failure;
        _message = 'Flashlight is not available on this camera.';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameraTransitioning) return;
    setState(() {
      _cameraTransitioning = true;
      _message = 'Switching camera…';
    });
    try {
      await _controller.switchCamera();
    } on MobileScannerException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = error;
        _state = QRScannerState.failure;
        _message = _cameraErrorMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = QRScannerState.failure;
        _message = 'Unable to switch camera.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cameraTransitioning = false;
          if (_state == QRScannerState.scanning) _message = null;
        });
      }
    }
  }

  bool _isDuplicateScan(String raw) {
    final now = DateTime.now();
    if (_processing || now.isBefore(_cooldownUntil)) return true;
    if (_lastScan == raw && now.difference(_lastScanAt) < _scanCooldown) {
      return true;
    }
    _lastScan = raw;
    _lastScanAt = now;
    _cooldownUntil = now.add(_scanCooldown);
    return false;
  }

  Future<void> _handleDetect(String? raw) async {
    if (raw == null ||
        raw.trim().isEmpty ||
        !_cameraReady ||
        _state == QRScannerState.success ||
        _isDuplicateScan(raw)) {
      return;
    }
    setState(() {
      _processing = true;
      _state = QRScannerState.loading;
      _message = 'Verifying student…';
    });

    try {
      final result = await widget.onScan(raw);
      if (!mounted) return;

      if (result == null) {
        setState(() {
          _state = QRScannerState.failure;
          _message = 'Student not recognized';
          _processing = false;
        });
        await Future<void>.delayed(_scanCooldown);
        if (mounted) {
          setState(() {
            _state = QRScannerState.scanning;
            _message = null;
          });
        }
        return;
      }

      final student = result['student'] as Map<String, dynamic>?;
      final status = result['status']?.toString();
      setState(() {
        _previewStudent = student;
        _state = QRScannerState.success;
        _message = status == 'already_marked'
            ? '${student?['name']} already marked'
            : '${student?['name']} marked present';
        _history.insert(
          0,
          ScanHistoryEntry(
            studentName: student?['name']?.toString() ?? 'Student',
            className: student?['className']?.toString() ?? '',
            timestamp: DateTime.now(),
            success: true,
            message: _message,
          ),
        );
        _processing = false;
      });

      await Future<void>.delayed(AppAnimations.fast);
      await _showConfirmation(student, status);
      if (!mounted) return;
      setState(() {
        _state = QRScannerState.scanning;
        _previewStudent = null;
        _message = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = QRScannerState.failure;
        _message = e.toString();
        _history.insert(
          0,
          ScanHistoryEntry(
            studentName: 'Unknown',
            className: '',
            timestamp: DateTime.now(),
            success: false,
            message: _message,
          ),
        );
        _processing = false;
      });
      await Future<void>.delayed(_scanCooldown);
      if (mounted) {
        setState(() {
          _state = QRScannerState.scanning;
          _message = null;
        });
      }
    }
  }

  Future<void> _showConfirmation(
    Map<String, dynamic>? student,
    String? status,
  ) async {
    if (student == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor:
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                status == 'already_marked'
                    ? Icons.info_outline
                    : Icons.check_circle,
                size: 48,
                color: status == 'already_marked'
                    ? Colors.deepOrange
                    : Colors.teal,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                student['name']?.toString() ?? 'Student',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                '${student['className']} • ${student['rollNo']}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                status == 'already_marked'
                    ? 'Attendance was already recorded today.'
                    : 'Attendance confirmed and parent notified.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Continue scanning',
                icon: Icons.qr_code_scanner,
                onPressed: () => Navigator.pop(context),
                expand: true,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= AppBreakpoints.desktop && _showHistory;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('QR Attendance'),
        actions: [
          IconButton(
            tooltip: 'Scan history',
            onPressed: () => setState(() => _showHistory = !_showHistory),
            icon: Badge(
              isLabelVisible: _history.isNotEmpty,
              label: Text('${_history.length}'),
              child: const Icon(Icons.history_rounded),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  fit: BoxFit.cover,
                  placeholderBuilder: (context, child) {
                    final error = _cameraError;
                    if (error != null) {
                      return _CameraStatusView(
                        title: _cameraErrorTitle(error),
                        message: _cameraErrorMessage(error),
                        actionLabel: 'Retry camera',
                        actionIcon: Icons.refresh_rounded,
                        onAction: _retryCamera,
                      );
                    }
                    return _CameraStatusView(
                      title: 'Starting camera',
                      message: 'Preparing the secure QR attendance scanner.',
                      actionLabel: 'Retry',
                      actionIcon: Icons.refresh_rounded,
                      onAction: _retryCamera,
                      loading: true,
                    );
                  },
                  onScannerStarted: (arguments) {
                    if (!mounted) return;
                    setState(() {
                      _cameraReady = arguments != null;
                      _cameraStarting = false;
                      _cameraError = null;
                      if (_message == 'Requesting camera access…' ||
                          _message == 'Camera is still starting…') {
                        _message = null;
                      }
                    });
                  },
                  onDetect: (capture) {
                    final barcode = capture.barcodes.firstOrNull;
                    _handleDetect(barcode?.rawValue);
                  },
                  errorBuilder: (context, error, child) {
                    return _CameraStatusView(
                      title: _cameraErrorTitle(error),
                      message: _cameraErrorMessage(error),
                      actionLabel: 'Retry camera',
                      actionIcon: Icons.refresh_rounded,
                      onAction: _retryCamera,
                    );
                  },
                ),
                QRScannerOverlay(state: _state, message: _message),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 72,
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  child: _PermissionBanner(
                    ready: _cameraReady,
                    starting: _cameraStarting,
                    error: _cameraError,
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: width < AppBreakpoints.desktop ? 140 : AppSpacing.xl,
                  child: _ScannerControls(
                    controller: _controller,
                    disabled: _cameraTransitioning || _cameraStarting,
                    onToggleTorch: _toggleTorch,
                    onSwitchCamera: _switchCamera,
                  ),
                ),
                if (_previewStudent != null)
                  Positioned(
                    bottom: width < AppBreakpoints.desktop ? 220 : 108,
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    child: _StudentPreviewCard(student: _previewStudent!),
                  ),
                if (_state == QRScannerState.loading || _cameraTransitioning)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              ],
            ),
          ),
          if (showSidebar) _ScanHistorySidebar(history: _history),
        ],
      ),
      bottomNavigationBar: width < AppBreakpoints.desktop
          ? _ScanHistoryBottomSheet(history: _history)
          : null,
    );
  }

  String _cameraErrorTitle(MobileScannerException error) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => 'Camera permission required',
      MobileScannerErrorCode.unsupported => 'No compatible camera found',
      _ => 'Camera unavailable',
    };
  }

  String _cameraErrorMessage(MobileScannerException error) {
    final details = error.errorDetails?.message;
    if (details != null && details.trim().isNotEmpty) return details;

    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => _permissionGuidance,
      MobileScannerErrorCode.unsupported =>
        'This device or browser cannot provide a camera stream. Use manual attendance or try another device.',
      _ =>
        'The camera did not initialize cleanly. Close other camera apps and try again.',
    };
  }

  String get _permissionGuidance {
    if (kIsWeb) {
      return 'Allow camera access in the browser prompt, then retry. If it was blocked, update site permissions from the address bar.';
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS =>
        'Allow camera access in macOS System Settings > Privacy & Security > Camera, then retry.',
      TargetPlatform.iOS =>
        'Allow camera access in iOS Settings > Secure School Hub > Camera, then retry.',
      TargetPlatform.android =>
        'Allow camera access in Android Settings > Apps > Secure School Hub > Permissions, then retry.',
      _ => 'Allow camera access in system settings, then retry.',
    };
  }
}

class _ScannerControls extends StatelessWidget {
  const _ScannerControls({
    required this.controller,
    required this.disabled,
    required this.onToggleTorch,
    required this.onSwitchCamera,
  });

  final MobileScannerController controller;
  final bool disabled;
  final VoidCallback onToggleTorch;
  final VoidCallback onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ValueListenableBuilder<TorchState>(
            valueListenable: controller.torchState,
            builder: (context, torch, _) {
              return _RoundScannerButton(
                tooltip: torch == TorchState.on
                    ? 'Turn flashlight off'
                    : 'Turn flashlight on',
                icon: torch == TorchState.on
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                onPressed: disabled ? null : onToggleTorch,
                active: torch == TorchState.on,
              );
            },
          ),
          const SizedBox(width: AppSpacing.md),
          ValueListenableBuilder<CameraFacing>(
            valueListenable: controller.cameraFacingState,
            builder: (context, facing, _) {
              return _RoundScannerButton(
                tooltip: facing == CameraFacing.back
                    ? 'Use front camera'
                    : 'Use back camera',
                icon: Icons.cameraswitch_rounded,
                onPressed: disabled ? null : onSwitchCamera,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoundScannerButton extends StatelessWidget {
  const _RoundScannerButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active
            ? Colors.teal.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.5),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: onPressed,
          color: Colors.white,
          disabledColor: Colors.white38,
          icon: Icon(icon),
        ),
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.ready,
    required this.starting,
    required this.error,
  });

  final bool ready;
  final bool starting;
  final MobileScannerException? error;

  @override
  Widget build(BuildContext context) {
    final text = error != null
        ? 'Camera needs attention'
        : starting
            ? 'Requesting camera permission'
            : ready
                ? 'Camera ready'
                : 'Camera offline';
    final color = error != null
        ? Theme.of(context).colorScheme.error
        : ready
            ? Colors.teal
            : Colors.white70;

    return IgnorePointer(
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: AppSpacing.borderRadiusSm,
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraStatusView extends StatelessWidget {
  const _CameraStatusView({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.loading = false,
  });

  final String title;
  final String message;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const CircularProgressIndicator(color: Colors.white)
              else
                const Icon(
                  Icons.videocam_off_outlined,
                  size: 56,
                  color: Colors.white70,
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: actionLabel,
                icon: actionIcon,
                onPressed: onAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentPreviewCard extends StatelessWidget {
  const _StudentPreviewCard({required this.student});

  final Map<String, dynamic> student;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      variant: GlassCardVariant.elevated,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.teal.withValues(alpha: 0.15),
            child: Text(
              (student['name']?.toString() ?? '?')[0].toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.teal,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name']?.toString() ?? 'Student',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                Text(
                  '${student['className']} • ${student['rollNo']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified, color: Colors.teal),
        ],
      ),
    );
  }
}

class _ScanHistorySidebar extends StatelessWidget {
  const _ScanHistorySidebar({required this.history});

  final List<ScanHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      child: _ScanHistoryList(history: history),
    );
  }
}

class _ScanHistoryBottomSheet extends StatelessWidget {
  const _ScanHistoryBottomSheet({required this.history});

  final List<ScanHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 120,
          child: _ScanHistoryList(history: history, horizontal: true),
        ),
      ),
    );
  }
}

class _ScanHistoryList extends StatelessWidget {
  const _ScanHistoryList({
    required this.history,
    this.horizontal = false,
  });

  final List<ScanHistoryEntry> history;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(child: Text('No scans yet'));
    }

    if (horizontal) {
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: history.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => SizedBox(
          width: 200,
          child: _HistoryTile(entry: history[i]),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Scan history',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemCount: history.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _HistoryTile(entry: history[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final ScanHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      variant: GlassCardVariant.flat,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            entry.success ? Icons.check_circle : Icons.error_outline,
            color: entry.success ? Colors.teal : scheme.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.studentName,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.className.isNotEmpty)
                  Text(
                    entry.className,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
