/// Responsive breakpoints and layout constants.
class AppBreakpoints {
  AppBreakpoints._();

  /// Screen width breakpoints.
  static const double mobile = 768.0;
  static const double tablet = 1024.0;
  static const double desktop = 1200.0;

  /// Sidebar dimensions.
  static const double sidebarExpanded = 240.0;
  static const double sidebarCollapsed = 72.0;

  /// Content area max width.
  static const double contentMaxWidth = 1200.0;

  /// Convenience helpers.
  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
}
