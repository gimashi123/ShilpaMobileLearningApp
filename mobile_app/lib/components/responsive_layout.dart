import 'package:flutter/material.dart';

/// A utility class to handle responsive layout logic and scaling
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  // Screen breakpoints
  static const double mobileLimit = 600;
  static const double tabletLimit = 1100;

  // Helper methods for screen type checking
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileLimit;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileLimit &&
      MediaQuery.of(context).size.width < tabletLimit;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletLimit;

  // Scaling helpers
  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;

  // Get dynamic font size
  static double getFontSize(BuildContext context, double baseSize) {
    if (isDesktop(context)) return baseSize * 1.5;
    if (isTablet(context)) return baseSize * 1.25;
    return baseSize;
  }

  // Get dynamic padding
  static double getPadding(BuildContext context, double basePadding) {
    if (isDesktop(context)) return basePadding * 2;
    if (isTablet(context)) return basePadding * 1.5;
    return basePadding;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    if (desktop != null && size.width >= tabletLimit) {
      return desktop!;
    }

    if (tablet != null && size.width >= mobileLimit) {
      return tablet!;
    }

    return mobile;
  }
}
