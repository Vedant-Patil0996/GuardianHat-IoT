import 'dart:async';
import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../models/alert_data.dart';
import 'alert_repository.dart';

/// Mock alert repository for UI development.
///
/// Fires a simulated FALL_DETECTED alert at a configurable interval.
class MockAlertRepository implements AlertRepository {
  Timer? _timer;
  final _random = Random();
  final _alertController = StreamController<AlertData>.broadcast();

  @override
  Stream<AlertData> get alertStream => _alertController.stream;

  @override
  Future<void> connect() async {
    _timer = Timer.periodic(
      Duration(milliseconds: AppConstants.mockAlertIntervalMs),
      (_) => _emitAlert(),
    );
  }

  void _emitAlert() {
    final prevAngle = 10.0 + _random.nextDouble() * 20.0;
    final delta = 50.0 + _random.nextDouble() * 40.0;

    _alertController.add(AlertData(
      event: 'FALL_DETECTED',
      previousAngle: double.parse(prevAngle.toStringAsFixed(1)),
      currentAngle: double.parse((prevAngle + delta).toStringAsFixed(1)),
      delta: double.parse(delta.toStringAsFixed(1)),
      mapsUrl: 'http://maps.google.com/?q=19.064500,72.835800',
    ));
  }

  @override
  void disconnect() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    disconnect();
    _alertController.close();
  }
}
