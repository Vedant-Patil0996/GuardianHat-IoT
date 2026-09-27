import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radii.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/mqtt_config.dart';
import '../../data/models/connection_state.dart';
import '../../providers/providers.dart';
import '../components/surface_card.dart';
import '../components/status_pill.dart';
import '../widgets/live_clock.dart';

/// Settings screen — MQTT configuration, app info, and mock mode toggle.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionAsync = ref.watch(connectionStateProvider);
    final connectionState =
        connectionAsync.valueOrNull ?? DeviceConnectionState.offline;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                height: MediaQuery.of(context).padding.top > 0
                    ? AppSpacing.lg
                    : AppSpacing.xl),
            Row(
              children: [
                Text('Settings', style: AppTextStyles.headlineLarge),
                const Spacer(),
                const LiveClock(),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Connection Status ──
            _sectionLabel('CONNECTION'),
            const SizedBox(height: AppSpacing.sm),
            SurfaceCard(
              child: Column(
                children: [
                  _settingRow(
                    icon: Icons.cloud_outlined,
                    label: 'Broker',
                    value: MqttConfig.defaultHost.length > 24
                        ? '${MqttConfig.defaultHost.substring(0, 24)}…'
                        : MqttConfig.defaultHost,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _settingRow(
                    icon: Icons.numbers,
                    label: 'Port',
                    value: '${MqttConfig.defaultPort}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _settingRow(
                    icon: Icons.circle,
                    label: 'Status',
                    trailing: StatusPill(
                      label: connectionState == DeviceConnectionState.live
                          ? 'Connected'
                          : connectionState ==
                                  DeviceConnectionState.reconnecting
                              ? 'Reconnecting'
                              : 'Offline',
                      color: connectionState == DeviceConnectionState.live
                          ? AppColors.success
                          : connectionState ==
                                  DeviceConnectionState.reconnecting
                              ? AppColors.warning
                              : AppColors.textTertiary,
                      isActive:
                          connectionState == DeviceConnectionState.live,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Topics ──
            _sectionLabel('MQTT TOPICS'),
            const SizedBox(height: AppSpacing.sm),
            SurfaceCard(
              child: Column(
                children: [
                  _settingRow(
                    icon: Icons.sensors,
                    label: 'Telemetry',
                    value: MqttConfig.topicTelemetry,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _settingRow(
                    icon: Icons.warning_amber_rounded,
                    label: 'Alerts',
                    value: MqttConfig.topicAlerts,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Development ──
            _sectionLabel('DEVELOPMENT'),
            const SizedBox(height: AppSpacing.sm),
            SurfaceCard(
              child: Column(
                children: [
                  _settingRow(
                    icon: Icons.bug_report_outlined,
                    label: 'Mock Data',
                    trailing: StatusPill(
                      label: AppConstants.kUseMockData ? 'Enabled' : 'Disabled',
                      color: AppConstants.kUseMockData
                          ? AppColors.warning
                          : AppColors.textTertiary,
                      isActive: AppConstants.kUseMockData,
                    ),
                  ),
                  if (AppConstants.kUseMockData) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warningSurface,
                        borderRadius: AppRadii.smallRadius,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Using simulated data. Set kUseMockData to false in app_constants.dart for real MQTT.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── About ──
            _sectionLabel('ABOUT'),
            const SizedBox(height: AppSpacing.sm),
            SurfaceCard(
              child: Column(
                children: [
                  _settingRow(
                    icon: Icons.shield_outlined,
                    label: 'App',
                    value: 'GuardianHat v1.0.0',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _settingRow(
                    icon: Icons.developer_board,
                    label: 'Device',
                    value: 'ESP32 + MPU6050',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _settingRow(
                    icon: Icons.code,
                    label: 'Protocol',
                    value: 'MQTT v3.1.1 (TLS)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: AppTextStyles.bodyMedium),
        const Spacer(),
        if (trailing != null)
          trailing
        else if (value != null)
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
      ],
    );
  }
}
