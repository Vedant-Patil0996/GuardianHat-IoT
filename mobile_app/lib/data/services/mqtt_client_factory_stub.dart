import 'package:mqtt_client/mqtt_client.dart';

MqttClient createPlatformMqttClient(String host, String clientId, int port) =>
    throw UnsupportedError('Unsupported platform for MQTT client');
