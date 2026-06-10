import 'package:flutter/material.dart';

/// 4px-based spacing scale, radii, and responsive breakpoints.
abstract final class AppSpacing {
  // ── Base unit ──────────────────────────────────────────────────────────
  static const double unit = 4;

  // ── Spacing scale ──────────────────────────────────────────────────────
  static const double xxs = unit; // 4
  static const double xs = unit * 2; // 8
  static const double sm = unit * 3; // 12
  static const double md = unit * 4; // 16
  static const double lg = unit * 6; // 24
  static const double xl = unit * 8; // 32
  static const double xxl = unit * 12; // 48
  static const double xxxl = unit * 16; // 64

  // ── Border radius ──────────────────────────────────────────────────────
  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 28;
  static const double radiusFull = 999;

  static const BorderRadius borderRadiusXs =
      BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl =
      BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusXxl =
      BorderRadius.all(Radius.circular(radiusXxl));

  // ── Page / section padding ─────────────────────────────────────────────
  static const EdgeInsets pagePaddingMobile =
      EdgeInsets.symmetric(horizontal: md, vertical: md);
  static const EdgeInsets pagePaddingTablet =
      EdgeInsets.symmetric(horizontal: lg, vertical: lg);
  static const EdgeInsets pagePaddingDesktop =
      EdgeInsets.symmetric(horizontal: xl, vertical: xl);

  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(lg);

  // ── Icon / control sizes ───────────────────────────────────────────────
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;

  static const double buttonHeightSm = 40;
  static const double buttonHeightMd = 48;
  static const double buttonHeightLg = 56;

  static const double maxContentWidth = 1280;
  static const double maxFormWidth = 480;
  static const double maxCardWidth = 640;
}

/// Responsive breakpoints aligned with Material adaptive guidance.
abstract final class AppBreakpoints {
  static const double mobile = 0;
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double wide = 1440;

  static bool isMobile(double width) => width < tablet;
  static bool isTablet(double width) => width >= tablet && width < desktop;
  static bool isDesktop(double width) => width >= desktop && width < wide;
  static bool isWide(double width) => width >= wide;

  /// Returns the current breakpoint name for layout decisions.
  static AppBreakpoint of(double width) {
    if (width >= wide) return AppBreakpoint.wide;
    if (width >= desktop) return AppBreakpoint.desktop;
    if (width >= tablet) return AppBreakpoint.tablet;
    return AppBreakpoint.mobile;
  }

  /// Column count for responsive grids (1–4).
  static int gridColumns(double width, {double minItemWidth = 220}) {
    if (width >= wide) return 4;
    if (width >= desktop) return 3;
    if (width >= tablet) return 2;
    final computed = (width / minItemWidth).floor();
    return computed.clamp(1, 2);
  }

  /// Page padding that scales with viewport width.
  static EdgeInsets pagePadding(double width) {
    final breakpoint = of(width);
    return switch (breakpoint) {
      AppBreakpoint.mobile => AppSpacing.pagePaddingMobile,
      AppBreakpoint.tablet => AppSpacing.pagePaddingTablet,
      AppBreakpoint.desktop || AppBreakpoint.wide =>
        AppSpacing.pagePaddingDesktop,
    };
  }
}

enum AppBreakpoint { mobile, tablet, desktop, wide }

/// Constrains child width and applies responsive horizontal padding.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = (constraints.hasBoundedWidth &&
                    constraints.maxWidth.isFinite
                ? constraints.maxWidth.clamp(0.0, double.infinity)
                : MediaQuery.sizeOf(context).width.clamp(0.0, double.infinity))
            .toDouble();
        final safeMaxWidth = maxWidth.isFinite && maxWidth > 0
            ? maxWidth
            : AppSpacing.maxContentWidth;
        final contentWidth = availableWidth.clamp(0.0, safeMaxWidth).toDouble();

        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 0,
              maxWidth: contentWidth,
            ),
            child: Padding(
              padding: AppBreakpoints.pagePadding(availableWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
