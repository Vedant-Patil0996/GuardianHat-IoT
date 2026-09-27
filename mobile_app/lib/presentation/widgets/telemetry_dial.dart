import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Instrument-grade arc gauge for distance telemetry.
///
/// Features:
/// - Animated arc with tick marks (10 cm intervals)
/// - Gradient stroke: cyan → white
/// - Danger zone marked in red below 10 cm
/// - Smooth interpolation between MQTT updates (300ms)
/// - Center: large metric value + unit label
class TelemetryDial extends StatelessWidget {
  final double value;
  final double maxValue;
  final String unit;
  final String label;

  const TelemetryDial({
    super.key,
    required this.value,
    this.maxValue = 100.0,
    this.unit = 'cm',
    this.label = 'DISTANCE',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.clamp(0, maxValue)),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(
            painter: _DialPainter(
              value: animatedValue,
              maxValue: maxValue,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    animatedValue.toStringAsFixed(1),
                    style: AppTextStyles.metricValue,
                  ),
                  Text(
                    unit,
                    style: AppTextStyles.metricUnit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  final double value;
  final double maxValue;

  _DialPainter({required this.value, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    const startAngle = 2.356; // ~135° (bottom-left)
    const sweepAngle = 4.712; // ~270° arc
    final valueRatio = (value / maxValue).clamp(0.0, 1.0);

    // ── Background track ──
    final trackPaint = Paint()
      ..color = AppColors.surfaceElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // ── Value arc (gradient) ──
    if (valueRatio > 0) {
      final isDanger = value < 10;
      final valuePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle * valueRatio,
          colors: isDanger
              ? [AppColors.danger, AppColors.danger.withValues(alpha: 0.7)]
              : [AppColors.accent, AppColors.textPrimary.withValues(alpha: 0.8)],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * valueRatio,
        false,
        valuePaint,
      );
    }

    // ── Tick marks (every 10 units) ──
    final tickPaint = Paint()
      ..color = AppColors.textTertiary.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (int i = 0; i <= 10; i++) {
      final tickAngle = startAngle + (sweepAngle * i / 10);
      final outerPoint = Offset(
        center.dx + (radius + 6) * cos(tickAngle),
        center.dy + (radius + 6) * sin(tickAngle),
      );
      final innerPoint = Offset(
        center.dx + (radius - (i % 5 == 0 ? 8 : 4)) * cos(tickAngle),
        center.dy + (radius - (i % 5 == 0 ? 8 : 4)) * sin(tickAngle),
      );
      canvas.drawLine(innerPoint, outerPoint, tickPaint);
    }

    // ── Value endpoint dot ──
    if (valueRatio > 0) {
      final dotAngle = startAngle + sweepAngle * valueRatio;
      final dotCenter = Offset(
        center.dx + radius * cos(dotAngle),
        center.dy + radius * sin(dotAngle),
      );
      canvas.drawCircle(
        dotCenter,
        4,
        Paint()..color = value < 10 ? AppColors.danger : AppColors.accent,
      );
      canvas.drawCircle(
        dotCenter,
        8,
        Paint()
          ..color = (value < 10 ? AppColors.danger : AppColors.accent)
              .withValues(alpha: 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.maxValue != maxValue;
}
