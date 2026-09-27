import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient createPlatformMqttClient(String host, String clientId, int port) {
  // HiveMQ Cloud WebSockets endpoint runs on port 8884 with path /mqtt
  final cleanHost = host
      .replaceAll('wss://', '')
      .replaceAll('ws://', '')
      .split('/')
      .first;
  final webPort = (port == 8883 || port == 1883) ? 8884 : port;
  final wsUrl = 'wss://$cleanHost/mqtt';

  final client = MqttBrowserClient.withPort(wsUrl, clientId, webPort)
    ..websocketProtocols = ['mqtt', 'mqttv3.1', 'mqttv3.1.1']
    ..port = webPort;
  return client;
}
