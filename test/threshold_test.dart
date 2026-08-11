import 'package:flutter_test/flutter_test.dart';
import 'package:smart_safety_badge/core/constants.dart';

void main() {
  test('Smart Safety Badge threshold is 150 BPM', () {
    expect(AppConstants.heartRateThreshold, 150);
  });

  test('150 BPM reaches the alert threshold', () {
    expect(150 >= AppConstants.heartRateThreshold, isTrue);
  });

  test('149 BPM does not reach the alert threshold', () {
    expect(149 >= AppConstants.heartRateThreshold, isFalse);
  });
}
