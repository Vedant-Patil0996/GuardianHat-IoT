/// Represents the current telemetry snapshot from the ESP32.
///
/// Maps to the JSON published on `smarthat/telemetry`:
/// ```json
/// {
///   "distance": 24.5,
///   "angle": 12.3,
///   "network": "Wi-Fi",
///   "motor_active": false,
///   "system_status": "NORMAL"
/// }
/// ```
class TelemetryData {
  final double distance;
  final double angle;
  final String network;
  final bool motorActive;
  final String systemStatus;
  final DateTime timestamp;

  TelemetryData({
    required this.distance,
    required this.angle,
    required this.network,
    required this.motorActive,
    required this.systemStatus,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TelemetryData.fromJson(Map<String, dynamic> json) {
    return TelemetryData(
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      angle: (json['angle'] as num?)?.toDouble() ?? 0.0,
      network: json['network'] as String? ?? 'Unknown',
      motorActive: json['motor_active'] as bool? ?? false,
      systemStatus: json['system_status'] as String? ?? 'UNKNOWN',
    );
  }

  bool get isAlertActive => systemStatus == 'ALERT_ACTIVE';
  bool get isObstacleNear => distance <= 55 && distance >= 5;

  /// Sentinel value for "no data received yet".
  static TelemetryData get empty => TelemetryData(
        distance: 0,
        angle: 0,
        network: '--',
        motorActive: false,
        systemStatus: 'UNKNOWN',
      );
}
