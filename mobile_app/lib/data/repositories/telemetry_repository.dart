import '../models/telemetry_data.dart';
import '../models/connection_state.dart';

/// Abstract telemetry data source.
/// Implemented by both MQTT (production) and Mock (development) repositories.
abstract class TelemetryRepository {
  /// Stream of telemetry updates.
  Stream<TelemetryData> get telemetryStream;

  /// Stream of connection state changes.
  Stream<DeviceConnectionState> get connectionStateStream;

  /// Current connection state.
  DeviceConnectionState get currentConnectionState;

  /// Initialize and start receiving data.
  Future<void> connect();

  /// Stop receiving data and clean up.
  void disconnect();

  /// Dispose all resources.
  void dispose();
}
