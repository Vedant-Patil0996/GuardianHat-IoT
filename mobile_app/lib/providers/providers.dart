import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../data/models/connection_state.dart';
import '../data/models/telemetry_data.dart';
import '../data/models/alert_data.dart';
import '../data/repositories/telemetry_repository.dart';
import '../data/repositories/alert_repository.dart';
import '../data/repositories/mock_telemetry_repository.dart';
import '../data/repositories/mock_alert_repository.dart';
import '../data/repositories/mqtt_telemetry_repository.dart';
import '../data/repositories/mqtt_alert_repository.dart';
import '../data/services/mqtt_service.dart';

// ── Services ──

final mqttServiceProvider = Provider<MqttService>((ref) {
  final service = MqttService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ── Repositories (swappable via kUseMockData) ──

final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  if (AppConstants.kUseMockData) {
    final repo = MockTelemetryRepository();
    ref.onDispose(() => repo.dispose());
    return repo;
  } else {
    final mqttService = ref.watch(mqttServiceProvider);
    final repo = MqttTelemetryRepository(mqttService);
    ref.onDispose(() => repo.dispose());
    return repo;
  }
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  if (AppConstants.kUseMockData) {
    final repo = MockAlertRepository();
    ref.onDispose(() => repo.dispose());
    return repo;
  } else {
    final mqttService = ref.watch(mqttServiceProvider);
    final repo = MqttAlertRepository(mqttService);
    ref.onDispose(() => repo.dispose());
    return repo;
  }
});

// ── Stream Providers ──

final telemetryStreamProvider = StreamProvider<TelemetryData>((ref) {
  final repo = ref.watch(telemetryRepositoryProvider);
  repo.connect();
  ref.onDispose(() => repo.disconnect());
  return repo.telemetryStream;
});

final connectionStateProvider = StreamProvider<DeviceConnectionState>((ref) {
  final repo = ref.watch(telemetryRepositoryProvider);
  return repo.connectionStateStream;
});

final alertStreamProvider = StreamProvider<AlertData>((ref) {
  final repo = ref.watch(alertRepositoryProvider);
  repo.connect();
  ref.onDispose(() => repo.disconnect());
  return repo.alertStream;
});

// ── State Providers ──

/// Holds the latest telemetry snapshot for synchronous access.
final latestTelemetryProvider =
    StateProvider<TelemetryData>((ref) => TelemetryData.empty);

/// Holds a rolling history of the last 60 telemetry snapshots (for charts).
final telemetryHistoryProvider =
    StateNotifierProvider<TelemetryHistoryNotifier, List<TelemetryData>>(
  (ref) {
    final notifier = TelemetryHistoryNotifier();
    // Listen to the live stream and add points
    ref.listen<AsyncValue<TelemetryData>>(
      telemetryStreamProvider,
      (previous, next) {
        if (next.hasValue && next.value != null && next.value != TelemetryData.empty) {
          notifier.addPoint(next.value!);
        } else if (next.hasValue && next.value == TelemetryData.empty) {
          notifier.clear();
        }
      },
    );
    return notifier;
  },
);

class TelemetryHistoryNotifier extends StateNotifier<List<TelemetryData>> {
  static const int maxPoints = 60; // 60 seconds of history at 1Hz

  TelemetryHistoryNotifier() : super([]);

  void addPoint(TelemetryData data) {
    if (state.length >= maxPoints) {
      state = [...state.skip(1), data];
    } else {
      state = [...state, data];
    }
  }

  void clear() {
    state = [];
  }
}

/// Holds the full alert history list.
final alertHistoryProvider =
    StateNotifierProvider<AlertHistoryNotifier, List<AlertData>>(
  (ref) => AlertHistoryNotifier(),
);

/// Whether the fall alert overlay is currently visible.
final showAlertOverlayProvider = StateProvider<bool>((ref) => false);

/// Active (unacknowledged) alert for the overlay.
final activeAlertProvider = StateProvider<AlertData?>((ref) => null);

class AlertHistoryNotifier extends StateNotifier<List<AlertData>> {
  AlertHistoryNotifier() : super([]);

  void addAlert(AlertData alert) {
    state = [alert, ...state];
  }

  void acknowledgeAlert(int index) {
    if (index >= 0 && index < state.length) {
      final updated = [...state];
      updated[index] = updated[index].copyWith(acknowledged: true);
      state = updated;
    }
  }

  void clearAll() {
    state = [];
  }
}
