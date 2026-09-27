import 'dart:async';

import '../../core/constants/mqtt_config.dart';
import '../models/telemetry_data.dart';
import '../models/connection_state.dart';
import '../services/mqtt_service.dart';
import 'telemetry_repository.dart';

/// Production telemetry repository backed by a real MQTT connection.
///
/// Features a 10-second watchdog timer: if the ESP32 stops publishing
/// telemetry packets for 10 seconds, the device state automatically drops
/// to [DeviceConnectionState.offline] and the telemetry stream resets to
/// [TelemetryData.empty] so stale/past data is never displayed as active.
class MqttTelemetryRepository implements TelemetryRepository {
  final MqttService _mqttService;
  final _telemetryController = StreamController<TelemetryData>.broadcast();
  final _connectionStateController =
      StreamController<DeviceConnectionState>.broadcast();

  StreamSubscription? _messageSub;
  StreamSubscription? _mqttStateSub;
  Timer? _watchdogTimer;

  DeviceConnectionState _deviceState = DeviceConnectionState.offline;

  /// Duration to wait before declaring the hardware device offline.
  static const Duration _deviceTimeout = Duration(seconds: 10);

  MqttTelemetryRepository(this._mqttService);

  @override
  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;

  @override
  Stream<DeviceConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  DeviceConnectionState get currentConnectionState => _deviceState;

  @override
  Future<void> connect() async {
    _mqttService.configure();
    await _mqttService.connect();

    // Listen to broker connectivity
    _mqttStateSub?.cancel();
    _mqttStateSub = _mqttService.connectionStateStream.listen((brokerState) {
      if (brokerState != DeviceConnectionState.live) {
        _watchdogTimer?.cancel();
        _setDeviceState(DeviceConnectionState.offline);
        _telemetryController.add(TelemetryData.empty);
      }
    });

    // Listen for incoming device telemetry packets
    _messageSub?.cancel();
    _messageSub = _mqttService.messageStream.listen((json) {
      final topic = json['_topic'] as String?;
      if (topic == MqttConfig.topicTelemetry) {
        // Device is actively transmitting
        _setDeviceState(DeviceConnectionState.live);
        _telemetryController.add(TelemetryData.fromJson(json));

        // Reset the 10-second watchdog
        _resetWatchdog();
      }
    });
  }

  void _resetWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(_deviceTimeout, () {
      // No packet received for 10 seconds -> device is powered off or disconnected
      _setDeviceState(DeviceConnectionState.offline);
      _telemetryController.add(TelemetryData.empty);
    });
  }

  void _setDeviceState(DeviceConnectionState newState) {
    if (_deviceState != newState) {
      _deviceState = newState;
      _connectionStateController.add(newState);
    }
  }

  @override
  void disconnect() {
    _watchdogTimer?.cancel();
    _messageSub?.cancel();
    _mqttStateSub?.cancel();
    _setDeviceState(DeviceConnectionState.offline);
    _telemetryController.add(TelemetryData.empty);
    _mqttService.disconnect();
  }

  @override
  void dispose() {
    disconnect();
    _telemetryController.close();
    _connectionStateController.close();
  }
}
