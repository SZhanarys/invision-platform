import 'dart:math' as math;

import 'package:flutter/widgets.dart';

final class AppResponsive {
  const AppResponsive._();

  static const double mobileBreakpoint = 640;
  static const double tabletBreakpoint = 1024;

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) =>
      screenWidth(context) < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static double inset(BuildContext context) {
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 20;
    return 24;
  }

  static double sectionGap(BuildContext context) {
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 20;
    return 24;
  }

  static double cardRadius(BuildContext context) {
    if (isMobile(context)) return 20;
    if (isTablet(context)) return 22;
    return 24;
  }

  static double heroRadius(BuildContext context) {
    if (isMobile(context)) return 24;
    if (isTablet(context)) return 26;
    return 28;
  }

  static double contentMaxWidth(BuildContext context, {double desktop = 920}) {
    final width = screenWidth(context);
    if (width < mobileBreakpoint) {
      return math.max(0, width - 32);
    }
    if (width < tabletBreakpoint) {
      return math.min(width - 40, desktop);
    }
    return desktop;
  }
}
