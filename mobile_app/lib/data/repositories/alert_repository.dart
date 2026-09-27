import '../models/alert_data.dart';

/// Abstract alert data source.
/// Implemented by both MQTT (production) and Mock (development) repositories.
abstract class AlertRepository {
  /// Stream of incoming fall-detection alerts.
  Stream<AlertData> get alertStream;

  /// Initialize and start listening.
  Future<void> connect();

  /// Stop listening and clean up.
  void disconnect();

  /// Dispose all resources.
  void dispose();
}
