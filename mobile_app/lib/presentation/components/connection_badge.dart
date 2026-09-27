import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';

/// A small pill-shaped badge showing network type or status.
class ConnectionBadge extends StatelessWidget {
  final String network;

  const ConnectionBadge({super.key, required this.network});

  @override
  Widget build(BuildContext context) {
    final isWifi = network == 'Wi-Fi';
    final icon = isWifi ? Icons.wifi : Icons.cell_tower;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.fullRadius,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: AppSpacing.xs),
          Text(
            network,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
