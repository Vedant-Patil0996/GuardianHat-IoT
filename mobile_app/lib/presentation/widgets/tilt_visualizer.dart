import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Directional tilt visualization for angle telemetry.
///
/// Instead of another generic circular gauge, this shows a tilting
/// device silhouette that rotates to match the hat's physical orientation.
/// Includes reference grid lines at 0°, 45°, 90°.
class TiltVisualizer extends StatelessWidget {
  final double angle;
  final double maxAngle;

  const TiltVisualizer({
    super.key,
    required this.angle,
    this.maxAngle = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: angle.clamp(-maxAngle, maxAngle)),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, animatedAngle, _) {
        return SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(
            painter: _TiltPainter(
              angle: animatedAngle,
              maxAngle: maxAngle,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    '${animatedAngle.toStringAsFixed(1)}°',
                    style: AppTextStyles.metricValue,
                  ),
                  Text(
                    'ANGLE',
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

class _TiltPainter extends CustomPainter {
  final double angle;
  final double maxAngle;

  _TiltPainter({required this.angle, required this.maxAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // ── Reference circle ──
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surfaceElevated
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── Reference grid lines (0°, 45°, 90°) ──
    final gridPaint = Paint()
      ..color = AppColors.textTertiary.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    // Horizontal center line (0°)
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );
    // Vertical center line
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    );
    // 45° diagonal lines
    final diag = radius * cos(pi / 4);
    canvas.drawLine(
      Offset(center.dx - diag, center.dy - diag),
      Offset(center.dx + diag, center.dy + diag),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx + diag, center.dy - diag),
      Offset(center.dx - diag, center.dy + diag),
      gridPaint,
    );

    // ── Reference labels ──
    final labelStyle = TextStyle(
      color: AppColors.textTertiary.withValues(alpha: 0.5),
      fontSize: 8,
      fontWeight: FontWeight.w500,
    );

    _drawLabel(canvas, '0°', Offset(center.dx + radius - 8, center.dy + 4), labelStyle);
    _drawLabel(canvas, '90°', Offset(center.dx - 8, center.dy - radius + 2), labelStyle);
    _drawLabel(canvas, '-90°', Offset(center.dx - 12, center.dy + radius - 10), labelStyle);
    _drawLabel(canvas, '±180°', Offset(center.dx - radius + 2, center.dy + 4), labelStyle);

    // ── Tilting indicator line ──
    final angleRad = angle * pi / 180;
    final lineLength = radius * 0.65;

    // The line tilts from the center, showing the current angle
    final lineEnd = Offset(
      center.dx + lineLength * cos(-angleRad + pi / 2),
      center.dy - lineLength * sin(-angleRad + pi / 2),
    );
    final lineStart = Offset(
      center.dx - lineLength * cos(-angleRad + pi / 2) * 0.3,
      center.dy + lineLength * sin(-angleRad + pi / 2) * 0.3,
    );

    final isWarning = angle.abs() > 45;
    final lineColor = isWarning ? AppColors.warning : AppColors.accent;

    canvas.drawLine(
      lineStart,
      lineEnd,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // ── Endpoint dot ──
    canvas.drawCircle(lineEnd, 5, Paint()..color = lineColor);
    canvas.drawCircle(
      lineEnd,
      10,
      Paint()..color = lineColor.withValues(alpha: 0.15),
    );

    // ── Center pivot ──
    canvas.drawCircle(center, 3, Paint()..color = AppColors.textSecondary);
  }

  void _drawLabel(Canvas canvas, String text, Offset position, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(_TiltPainter oldDelegate) =>
      oldDelegate.angle != angle;
}
