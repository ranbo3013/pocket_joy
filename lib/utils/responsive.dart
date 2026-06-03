import 'package:flutter/widgets.dart';

/// Responsive scaling utilities.
/// Reference: Visual Asset Spec §10

/// Breakpoints
const _smallScreenMax = 375.0;
const _standardScreenMax = 414.0;

/// Returns scale factor for the bag widget based on screen width.
double bagScale(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width <= _smallScreenMax) return 0.7;
  if (width <= _standardScreenMax) return 1.0;
  return 1.1;
}

/// Returns spacing scale factor for responsive layout.
double spacingScale(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width <= _smallScreenMax) return 0.85;
  if (width <= _standardScreenMax) return 1.0;
  return 1.1;
}

/// Returns adjusted coin display font size.
double coinFontSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width <= _smallScreenMax) return 28.0;
  return 36.0;
}
