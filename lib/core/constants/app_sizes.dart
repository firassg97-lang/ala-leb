import 'package:flutter/material.dart';

class AppSizes {
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double productCardWidth(BuildContext context) {
    final w = screenWidth(context);
    if (w > 600) return (w - 64) / 3;
    return (w - 48) / 2;
  }

  static int gridCrossAxisCount(BuildContext context) {
    return screenWidth(context) > 600 ? 3 : 2;
  }

  static double sp(BuildContext context, double size) =>
      size * MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2);

  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  static const double iconS = 16.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;

  static const double buttonHeight = 52.0;
  static const double inputHeight = 52.0;
  static const double navBarHeight = 64.0;
  static const double adCardHeight = 280.0;
}
