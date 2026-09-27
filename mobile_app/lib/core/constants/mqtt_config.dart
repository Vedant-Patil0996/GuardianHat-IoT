/// MQTT broker configuration — non-secret values and fallbacks.
class MqttConfig {
  MqttConfig._();

  static const String defaultHost = 'your_broker_host_here';
  static const int defaultPort = 8883;

  static const String defaultUsername = '';
  static const String defaultPassword = '';

  static const String topicTelemetry = 'smarthat/telemetry';
  static const String topicAlerts = 'smarthat/alerts';

  static const String clientIdPrefix = 'GuardianHat_Flutter_';
}
