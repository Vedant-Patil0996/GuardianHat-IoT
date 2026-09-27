import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/providers.dart';
import '../widgets/alert_history_tile.dart';
import '../widgets/live_clock.dart';

/// Alert history screen — shows a chronological list of fall-detection events.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertHistoryProvider);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top > 0
                  ? AppSpacing.lg
                  : AppSpacing.xl,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text('Alerts', style: AppTextStyles.headlineLarge),
                  const Spacer(),
                  const LiveClock(),
                  if (alerts.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        ref.read(alertHistoryProvider.notifier).clearAll();
                      },
                      child: Text(
                        'Clear All',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (alerts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AlertHistoryTile(
                        alert: alerts[index],
                        onTap: () {
                          if (!alerts[index].acknowledged) {
                            ref
                                .read(alertHistoryProvider.notifier)
                                .acknowledgeAlert(index);
                          }
                        },
                      ),
                    );
                  },
                  childCount: alerts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 36,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'All Clear',
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No fall alerts have been detected.\nThe device is monitoring normally.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
