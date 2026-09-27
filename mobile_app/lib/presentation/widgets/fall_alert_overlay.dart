import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';
import '../../data/models/alert_data.dart';
import '../components/primary_button.dart';
import '../components/surface_card.dart';

/// Full-screen fall detection alert overlay.
///
/// Design:
/// - Background dims to 60% black scrim
/// - Single scale pulse on entry (not continuous flashing)
/// - Red accent glow around detail card
/// - Haptic feedback on show
/// - "View Location" opens maps URL
/// - "Acknowledge" dismisses overlay
class FallAlertOverlay extends StatefulWidget {
  final AlertData alert;
  final VoidCallback onAcknowledge;

  const FallAlertOverlay({
    super.key,
    required this.alert,
    required this.onAcknowledge,
  });

  @override
  State<FallAlertOverlay> createState() => _FallAlertOverlayState();
}

class _FallAlertOverlayState extends State<FallAlertOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Fire haptic and start animation
    HapticFeedback.heavyImpact();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openLocation() async {
    final url = Uri.parse(widget.alert.mapsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          color: AppColors.scrim.withValues(alpha: _fadeAnimation.value * 0.85),
          child: SafeArea(
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.dangerSurface,
              boxShadow: AppShadows.dangerGlow,
            ),
            child: const Icon(
              Icons.warning_rounded,
              size: 40,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            'FALL DETECTED',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.danger,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Delta value
          Text(
            '${widget.alert.delta.toStringAsFixed(1)}°',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Angle change detected',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Detail card
          Container(
            decoration: BoxDecoration(
              boxShadow: AppShadows.dangerGlow,
              borderRadius: AppRadii.largeRadius,
            ),
            child: SurfaceCard(
              color: AppColors.dangerMuted.withValues(alpha: 0.3),
              child: Column(
                children: [
                  _detailRow('Previous', '${widget.alert.previousAngle.toStringAsFixed(1)}°'),
                  const SizedBox(height: AppSpacing.md),
                  Divider(color: AppColors.danger.withValues(alpha: 0.2), height: 1),
                  const SizedBox(height: AppSpacing.md),
                  _detailRow('Current', '${widget.alert.currentAngle.toStringAsFixed(1)}°'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // View Location button
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'VIEW LOCATION',
              icon: Icons.location_on_outlined,
              onPressed: _openLocation,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Acknowledge
          TextButton(
            onPressed: widget.onAcknowledge,
            child: Text(
              'Acknowledge',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
