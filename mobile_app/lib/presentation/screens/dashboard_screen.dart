import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/connection_state.dart';
import '../../data/models/telemetry_data.dart';
import '../../providers/providers.dart';
import '../components/connection_badge.dart';
import '../components/glass_card.dart';
import '../components/live_indicator.dart';
import '../components/section_header.dart';
import '../components/surface_card.dart';
import '../components/status_pill.dart';
import '../widgets/device_visualization.dart';
import '../widgets/telemetry_dial.dart';
import '../widgets/tilt_visualizer.dart';

/// Main dashboard screen — the hero view of the app.
///
/// Layout:
///   Header (app name + live indicator)
///   Hero device visualization (glass card)
///   Telemetry dials row (distance + angle)
///   Status cards row (motor + network)
///   Last update timestamp
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final telemetryAsync = ref.watch(telemetryStreamProvider);
    final connectionAsync = ref.watch(connectionStateProvider);

    // Update latest telemetry state for synchronous access elsewhere
    telemetryAsync.whenData((data) {
      Future.microtask(() {
        ref.read(latestTelemetryProvider.notifier).state = data;
      });
    });

    final telemetry = ref.watch(latestTelemetryProvider);
    final connectionState = connectionAsync.valueOrNull ??
        DeviceConnectionState.offline;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + AppSpacing.lg),

          // ── Header ──
          _buildHeader(connectionState, telemetry),
          const SizedBox(height: AppSpacing.xxl),

          // ── Hero Device ──
          Center(
            child: GlassCard(
              child: DeviceVisualization(
                isConnected: connectionState == DeviceConnectionState.live,
                angle: telemetry.angle,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // ── Telemetry Dials ──
          const SectionHeader(title: 'TELEMETRY'),
          Row(
            children: [
              Expanded(
                child: SurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                    horizontal: AppSpacing.sm,
                  ),
                  child: Center(
                    child: TelemetryDial(
                      value: telemetry.distance,
                      maxValue: 100,
                      unit: 'cm',
                      label: 'DISTANCE',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg,
                    horizontal: AppSpacing.sm,
                  ),
                  child: Center(
                    child: TiltVisualizer(
                      angle: telemetry.angle,
                      maxAngle: 90,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Status Cards ──
          const SectionHeader(title: 'DEVICE STATUS'),
          Row(
            children: [
              Expanded(
                child: SurfaceCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: telemetry.motorActive
                              ? AppColors.warningSurface
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.vibration,
                          size: 20,
                          color: telemetry.motorActive
                              ? AppColors.warning
                              : AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Motor', style: AppTextStyles.bodySmall),
                            const SizedBox(height: 2),
                            StatusPill(
                              label: telemetry.motorActive ? 'Active' : 'Idle',
                              color: telemetry.motorActive
                                  ? AppColors.warning
                                  : AppColors.textTertiary,
                              isActive: telemetry.motorActive,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SurfaceCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accentSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          telemetry.network == 'Wi-Fi'
                              ? Icons.wifi
                              : Icons.cell_tower,
                          size: 20,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Network', style: AppTextStyles.bodySmall),
                            const SizedBox(height: 2),
                            StatusPill(
                              label: connectionState == DeviceConnectionState.live
                                  ? telemetry.network
                                  : 'Offline',
                              color: connectionState == DeviceConnectionState.live
                                  ? AppColors.accent
                                  : AppColors.textTertiary,
                              isActive: connectionState == DeviceConnectionState.live,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Last Update ──
          Center(
            child: Text(
              connectionState == DeviceConnectionState.live
                  ? 'Live data — updated ${_formatTimestamp(telemetry.timestamp)}'
                  : connectionState == DeviceConnectionState.reconnecting
                      ? 'Reconnecting to MQTT broker...'
                      : 'Device offline — waiting for live telemetry...',
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _buildHeader(
      DeviceConnectionState connectionState, TelemetryData telemetry) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GuardianHat', style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Text(
                    connectionState == DeviceConnectionState.live
                        ? 'Connected'
                        : connectionState == DeviceConnectionState.reconnecting
                            ? 'Reconnecting'
                            : 'Disconnected',
                    style: AppTextStyles.bodyMedium,
                  ),
                  if (connectionState == DeviceConnectionState.live &&
                      telemetry.network != '--') ...[
                    Text(' • ', style: AppTextStyles.bodyMedium),
                    ConnectionBadge(network: telemetry.network),
                  ],
                ],
              ),
            ],
          ),
        ),
        LiveIndicator(state: connectionState),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 5) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return DateFormat('HH:mm').format(timestamp);
  }
}
