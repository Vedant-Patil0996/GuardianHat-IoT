import 'dart:async';
import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../models/telemetry_data.dart';
import '../models/connection_state.dart';
import 'telemetry_repository.dart';

/// Mock telemetry repository for UI development without an ESP32.
///
/// Produces realistic-looking telemetry data:
/// - Distance oscillates between 10–80 cm (sine wave)
/// - Angle drifts between 0–45° (random walk)
/// - Motor activates when distance < 55 cm
/// - Network randomly toggles between Wi-Fi and SIM800L
class MockTelemetryRepository implements TelemetryRepository {
  Timer? _timer;
  final _random = Random();
  int _tick = 0;
  double _currentAngle = 10.0;

  final _telemetryController = StreamController<TelemetryData>.broadcast();
  final _connectionController =
      StreamController<DeviceConnectionState>.broadcast();

  DeviceConnectionState _state = DeviceConnectionState.offline;

  @override
  Stream<TelemetryData> get telemetryStream => _telemetryController.stream;

  @override
  Stream<DeviceConnectionState> get connectionStateStream =>
      _connectionController.stream;

  @override
  DeviceConnectionState get currentConnectionState => _state;

  @override
  Future<void> connect() async {
    // Simulate a brief connection delay
    _updateState(DeviceConnectionState.reconnecting);
    await Future.delayed(const Duration(milliseconds: 800));
    _updateState(DeviceConnectionState.live);

    _timer = Timer.periodic(
      Duration(milliseconds: AppConstants.mockTelemetryIntervalMs),
      (_) => _emitTelemetry(),
    );
  }

  void _emitTelemetry() {
    _tick++;

    // Sine-wave distance (10–80 cm)
    final distance = 45.0 + 35.0 * sin(_tick * 0.08);

    // Random-walk angle (clamped 0–45°)
    _currentAngle += (_random.nextDouble() - 0.5) * 4.0;
    _currentAngle = _currentAngle.clamp(0.0, 45.0);

    // Motor active when distance is in proximity zone
    final motorActive = distance >= 5 && distance <= 55;

    // Occasionally toggle network
    final network =
        (_tick % 40 < 35) ? 'Wi-Fi' : 'SIM800L';

    _telemetryController.add(TelemetryData(
      distance: double.parse(distance.toStringAsFixed(1)),
      angle: double.parse(_currentAngle.toStringAsFixed(1)),
      network: network,
      motorActive: motorActive,
      systemStatus: 'NORMAL',
    ));
  }

  void _updateState(DeviceConnectionState state) {
    _state = state;
    _connectionController.add(state);
  }

  @override
  void disconnect() {
    _timer?.cancel();
    _timer = null;
    _updateState(DeviceConnectionState.offline);
  }

  @override
  void dispose() {
    disconnect();
    _telemetryController.close();
    _connectionController.close();
  }
}
