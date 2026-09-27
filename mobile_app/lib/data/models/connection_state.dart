/// Represents the app's connection to the MQTT broker.
enum DeviceConnectionState {
  /// Actively receiving data from the broker.
  live,

  /// Connection lost, attempting to reconnect.
  reconnecting,

  /// No connection to the broker.
  offline,
}
