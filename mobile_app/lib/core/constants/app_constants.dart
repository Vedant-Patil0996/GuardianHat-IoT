/// App-wide constants and feature flags.
class AppConstants {
  AppConstants._();

  /// Set to true to use mock data instead of a real MQTT broker.
  /// Toggle this during UI development when no ESP32 is available.
  static const bool kUseMockData = false;

  /// App name shown in the UI.
  static const String appName = 'GuardianHat';

  /// How often the mock repo emits telemetry (milliseconds).
  static const int mockTelemetryIntervalMs = 1000;

  /// How often the mock repo fires a test alert (milliseconds).
  static const int mockAlertIntervalMs = 30000;

  /// Duration for metric value animations (milliseconds).
  static const int metricAnimationDurationMs = 300;

  /// Maximum distance value for the dial scale (cm).
  static const double maxDistance = 100.0;

  /// Maximum angle value for the tilt visualization (degrees).
  static const double maxAngle = 90.0;
}
