/// Represents a fall-detection alert from the ESP32.
///
/// Maps to the JSON published on `smarthat/alerts`:
/// ```json
/// {
///   "event": "FALL_DETECTED",
///   "previous_angle": 15.2,
///   "current_angle": 75.8,
///   "delta": 60.6,
///   "maps_url": "http://maps.google.com/?q=19.064500,72.835800"
/// }
/// ```
class AlertData {
  final String event;
  final double previousAngle;
  final double currentAngle;
  final double delta;
  final String mapsUrl;
  final DateTime timestamp;
  final bool acknowledged;

  AlertData({
    required this.event,
    required this.previousAngle,
    required this.currentAngle,
    required this.delta,
    required this.mapsUrl,
    DateTime? timestamp,
    this.acknowledged = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AlertData.fromJson(Map<String, dynamic> json) {
    return AlertData(
      event: json['event'] as String? ?? 'UNKNOWN',
      previousAngle: (json['previous_angle'] as num?)?.toDouble() ?? 0.0,
      currentAngle: (json['current_angle'] as num?)?.toDouble() ?? 0.0,
      delta: (json['delta'] as num?)?.toDouble() ?? 0.0,
      mapsUrl: json['maps_url'] as String? ?? '',
    );
  }

  bool get isFallDetected => event == 'FALL_DETECTED';

  AlertData copyWith({bool? acknowledged}) {
    return AlertData(
      event: event,
      previousAngle: previousAngle,
      currentAngle: currentAngle,
      delta: delta,
      mapsUrl: mapsUrl,
      timestamp: timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }
}
