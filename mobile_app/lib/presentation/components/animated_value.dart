import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

/// Smoothly interpolated numerical display.
///
/// Tweens from the previous value to the new value over [duration],
/// preventing jittery raw MQTT updates on the UI.
class AnimatedValue extends StatelessWidget {
  final double value;
  final String unit;
  final TextStyle? valueStyle;
  final TextStyle? unitStyle;
  final Duration duration;
  final int decimals;

  const AnimatedValue({
    super.key,
    required this.value,
    this.unit = '',
    this.valueStyle,
    this.unitStyle,
    this.duration = const Duration(milliseconds: 300),
    this.decimals = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              animatedValue.toStringAsFixed(decimals),
              style: valueStyle ?? AppTextStyles.metricValue,
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: unitStyle ?? AppTextStyles.metricUnit,
              ),
            ],
          ],
        );
      },
    );
  }
}
