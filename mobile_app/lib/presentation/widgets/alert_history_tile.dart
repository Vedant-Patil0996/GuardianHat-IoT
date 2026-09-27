import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/alert_data.dart';
import '../components/surface_card.dart';
import '../components/status_pill.dart';

/// Single alert entry in the alert history list.
class AlertHistoryTile extends StatelessWidget {
  final AlertData alert;
  final VoidCallback? onTap;

  const AlertHistoryTile({
    super.key,
    required this.alert,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('dd MMM yyyy');

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.dangerSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  size: 18,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fall Detected',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${dateFormat.format(alert.timestamp)} • ${timeFormat.format(alert.timestamp)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: alert.acknowledged ? 'Seen' : 'New',
                color: alert.acknowledged
                    ? AppColors.textTertiary
                    : AppColors.danger,
                isActive: !alert.acknowledged,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricColumn('Delta', '${alert.delta.toStringAsFixed(1)}°'),
                Container(width: 1, height: 30, color: AppColors.border),
                _metricColumn('Previous', '${alert.previousAngle.toStringAsFixed(1)}°'),
                Container(width: 1, height: 30, color: AppColors.border),
                _metricColumn('Current', '${alert.currentAngle.toStringAsFixed(1)}°'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.titleMedium),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
