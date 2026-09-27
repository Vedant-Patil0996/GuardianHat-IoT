import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../core/constants/mqtt_config.dart';
import '../models/connection_state.dart';
import 'mqtt_client_factory.dart';

/// Low-level MQTT service — connects to HiveMQ Cloud over TLS/WSS.
///
/// Exposes raw message streams. The repository layer subscribes to these
/// and converts them into typed models. The UI never touches this class.
class MqttService {
  MqttClient? _client;
  Timer? _reconnectTimer;

  final _connectionStateController =
      StreamController<DeviceConnectionState>.broadcast();
  final _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  String _host = MqttConfig.defaultHost;
  int _port = MqttConfig.defaultPort;
  String _username = MqttConfig.defaultUsername;
  String _password = MqttConfig.defaultPassword;

  /// Stream of connection state changes.
  Stream<DeviceConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Stream of decoded JSON messages from any subscribed topic.
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  DeviceConnectionState _currentState = DeviceConnectionState.offline;
  DeviceConnectionState get currentState => _currentState;

  /// Initialize credentials from .env or provided values.
  void configure({
    String? host,
    int? port,
    String? username,
    String? password,
  }) {
    _host = (host != null && host.isNotEmpty)
        ? host
        : (dotenv.env['MQTT_HOST']?.isNotEmpty == true
            ? dotenv.env['MQTT_HOST']!
            : MqttConfig.defaultHost);
    _port = port ??
        int.tryParse(dotenv.env['MQTT_PORT'] ?? '') ??
        MqttConfig.defaultPort;
    _username = (username != null && username.isNotEmpty)
        ? username
        : (dotenv.env['MQTT_USERNAME']?.isNotEmpty == true
            ? dotenv.env['MQTT_USERNAME']!
            : MqttConfig.defaultUsername);
    _password = (password != null && password.isNotEmpty)
        ? password
        : (dotenv.env['MQTT_PASSWORD']?.isNotEmpty == true
            ? dotenv.env['MQTT_PASSWORD']!
            : MqttConfig.defaultPassword);
  }

  /// Connect to the MQTT broker.
  Future<void> connect() async {
    // If already connected or connecting, avoid restarting
    if (_client != null &&
        _client!.connectionStatus?.state == MqttConnectionState.connected) {
      debugPrint('[MQTT] Already connected to broker.');
      return;
    }

    if (_client != null) {
      disconnect();
    }

    final clientId =
        '${MqttConfig.clientIdPrefix}${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('[MQTT] Connecting to $_host:$_port as $clientId (user: $_username)...');

    _client = getPlatformMqttClient(_host, clientId, _port)
      ..keepAlivePeriod = 30
      ..autoReconnect = true
      ..onAutoReconnect = _onAutoReconnect
      ..onAutoReconnected = _onAutoReconnected
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..logging(on: false)
      ..setProtocolV311();

    _updateState(DeviceConnectionState.reconnecting);

    try {
      final status = await _client!.connect(_username, _password);
      debugPrint('[MQTT] Connection state: ${status?.state}, returnCode: ${status?.returnCode}');
    } catch (e) {
      debugPrint('[MQTT] Connect error: $e');
      _updateState(DeviceConnectionState.offline);
      _scheduleReconnect();
      return;
    }

    if (_client!.connectionStatus?.state == MqttConnectionState.connected) {
      debugPrint('[MQTT] Successfully connected to HiveMQ! Subscribing to topics...');
      _subscribe(MqttConfig.topicTelemetry);
      _subscribe(MqttConfig.topicAlerts);

      _client!.updates?.listen((List<MqttReceivedMessage<MqttMessage>> msgs) {
        for (final msg in msgs) {
          final payload = msg.payload as MqttPublishMessage;
          final text = MqttPublishPayload.bytesToStringAsString(
              payload.payload.message);
          debugPrint('[MQTT] Message received on [${msg.topic}]: $text');
          try {
            final json = jsonDecode(text) as Map<String, dynamic>;
            json['_topic'] = msg.topic;
            _messageController.add(json);
          } catch (err) {
            debugPrint('[MQTT] JSON parse error: $err');
          }
        }
      });
    } else {
      debugPrint('[MQTT] Connection was not established. State: ${_client!.connectionStatus?.state}');
      _updateState(DeviceConnectionState.offline);
      _scheduleReconnect();
    }
  }

  void _subscribe(String topic) {
    debugPrint('[MQTT] Subscribing to $topic');
    _client?.subscribe(topic, MqttQos.atMostOnce);
  }

  void _onConnected() {
    debugPrint('[MQTT] Event onConnected fired.');
    _updateState(DeviceConnectionState.live);
    _reconnectTimer?.cancel();
  }

  void _onDisconnected() {
    debugPrint('[MQTT] Event onDisconnected fired.');
    _updateState(DeviceConnectionState.offline);
    _scheduleReconnect();
  }

  void _onAutoReconnect() {
    debugPrint('[MQTT] Event onAutoReconnect fired.');
    _updateState(DeviceConnectionState.reconnecting);
  }

  void _onAutoReconnected() {
    debugPrint('[MQTT] Event onAutoReconnected fired. Resubscribing...');
    _updateState(DeviceConnectionState.live);
    _subscribe(MqttConfig.topicTelemetry);
    _subscribe(MqttConfig.topicAlerts);
  }

  void _updateState(DeviceConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_currentState != DeviceConnectionState.live) {
        connect();
      }
    });
  }

  /// Disconnect and clean up.
  void disconnect() {
    _reconnectTimer?.cancel();
    _client?.disconnect();
    _client = null;
    _updateState(DeviceConnectionState.offline);
  }

  /// Dispose all resources.
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _messageController.close();
  }
}
