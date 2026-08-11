class AppConstants {
  static const String appName = 'SMART SAFETY BADGE';

  // User-defined project safety threshold.
  // 150 BPM is NOT a medical diagnosis; it is the badge alert threshold.
  static const int heartRateThreshold = 150;

  // Start in demo mode so the project runs before Firebase is configured.
  // After running `flutterfire configure`, set this to true.
  static const bool useFirebase = false;

  // Generic BLE UUIDs. Change these to match the ESP32 firmware.
  static const String serviceUuid =
      '12345678-1234-1234-1234-1234567890AB';
  static const String telemetryCharacteristicUuid =
      '12345678-1234-1234-1234-1234567890AC';
  static const String commandCharacteristicUuid =
      '12345678-1234-1234-1234-1234567890AD';

  static const String defaultSerialNumber = 'SN30001234567';
  static const String defaultFirmware = '1.2.5';
  static const String defaultBadgeName = 'Smart Badge 01';

  static const double demoLatitude = 40.7128;
  static const double demoLongitude = -74.0060;
}
