import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketjoy/config/design_tokens.dart';
import 'package:pocketjoy/config/constants.dart';

void main() {
  test('Design tokens should have valid values', () {
    expect(AppColors.bgPrimary, isA<Color>());
    expect(AppColors.goldPrimary, isA<Color>());
  });

  test('Constants should have valid values', () {
    expect(dailyWorkHours, 8);
    expect(goldBarThreshold, 1000);
    expect(defaultIntervalMin, 15);
    expect(defaultIntervalMax, 300);
  });
}
