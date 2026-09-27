import 'dart:async';

import '../../core/constants/mqtt_config.dart';
import '../models/alert_data.dart';
import '../services/mqtt_service.dart';
import 'alert_repository.dart';

/// Production alert repository backed by a real MQTT connection.
class MqttAlertRepository implements AlertRepository {
  final MqttService _mqttService;
  final _alertController = StreamController<AlertData>.broadcast();
  StreamSubscription? _messageSub;

  MqttAlertRepository(this._mqttService);

  @override
  Stream<AlertData> get alertStream => _alertController.stream;

  @override
  Future<void> connect() async {
    // Assumes MqttService is already connected by TelemetryRepository.
    _messageSub = _mqttService.messageStream.listen((json) {
      final topic = json['_topic'] as String?;
      if (topic == MqttConfig.topicAlerts) {
        _alertController.add(AlertData.fromJson(json));
      }
    });
  }

  @override
  void disconnect() {
    _messageSub?.cancel();
  }

  @override
  void dispose() {
    disconnect();
    _alertController.close();
  }
}
