import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Small process-wide safety layer for frontend-only interaction cleanup.
class FrontendStabilityService {
  FrontendStabilityService._();

  static final FrontendStabilityService instance = FrontendStabilityService._();

  final Set<VoidCallback> _cleanupCallbacks = <VoidCallback>{};
  bool _timingsEnabled = false;

  void registerCleanup(VoidCallback callback) {
    _cleanupCallbacks.add(callback);
  }

  void unregisterCleanup(VoidCallback callback) {
    _cleanupCallbacks.remove(callback);
  }

  void resetInteractions() {
    for (final callback in List<VoidCallback>.from(_cleanupCallbacks)) {
      try {
        callback();
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'frontend stability',
            context: ErrorDescription('while cleaning up frontend overlays'),
          ),
        );
      }
    }
  }

  void enableFrameDiagnostics() {
    if (_timingsEnabled) return;
    _timingsEnabled = true;
    SchedulerBinding.instance.addTimingsCallback(_handleTimings);
  }

  void _handleTimings(List<FrameTiming> timings) {
    if (!kDebugMode) return;
    for (final timing in timings) {
      final buildMs = timing.buildDuration.inMilliseconds;
      final rasterMs = timing.rasterDuration.inMilliseconds;
      if (buildMs > 16 || rasterMs > 16) {
        debugPrint(
          '[frame] build=${buildMs}ms raster=${rasterMs}ms '
          'total=${timing.totalSpan.inMilliseconds}ms',
        );
      }
    }
  }
}
