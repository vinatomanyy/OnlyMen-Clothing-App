import 'package:flutter/material.dart';

class Responsive {
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  static double maxWidth(BuildContext context) =>
      isTablet(context) ? 900 : double.infinity;

  static int gridColumns(BuildContext context) =>
      isTablet(context) ? 3 : 2;

  static double horizontalPadding(BuildContext context) =>
      isTablet(context) ? 32 : 16;
}
