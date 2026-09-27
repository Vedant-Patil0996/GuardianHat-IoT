import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

/// Hero device visualization — a stylized smart helmet illustration.
///
/// Drawn with CustomPainter for a clean, scalable look.
/// Features a subtle cyan accent glow.
class DeviceVisualization extends StatelessWidget {
  final bool isConnected;
  final double angle;

  const DeviceVisualization({
    super.key,
    this.isConnected = true,
    this.angle = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: angle.clamp(0, 90)),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, animatedAngle, _) {
        return Container(
          decoration: isConnected
              ? BoxDecoration(
                  boxShadow: AppShadows.glow,
                  shape: BoxShape.circle,
                )
              : null,
          child: SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _HelmetPainter(
                isConnected: isConnected,
                tiltAngle: animatedAngle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HelmetPainter extends CustomPainter {
  final bool isConnected;
  final double tiltAngle;

  _HelmetPainter({required this.isConnected, required this.tiltAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 180;

    // Save canvas state and apply a subtle tilt
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tiltAngle * pi / 180 * 0.15); // Subtle visual tilt
    canvas.translate(-center.dx, -center.dy);

    final accentColor = isConnected ? AppColors.accent : AppColors.textTertiary;

    // ── Outer ring (device boundary) ──
    canvas.drawCircle(
      center,
      70 * scale,
      Paint()
        ..color = AppColors.surfaceElevated
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      70 * scale,
      Paint()
        ..color = accentColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // ── Helmet dome (top arc) ──
    final domePath = Path()
      ..moveTo(center.dx - 40 * scale, center.dy + 10 * scale)
      ..quadraticBezierTo(
        center.dx - 45 * scale,
        center.dy - 35 * scale,
        center.dx,
        center.dy - 40 * scale,
      )
      ..quadraticBezierTo(
        center.dx + 45 * scale,
        center.dy - 35 * scale,
        center.dx + 40 * scale,
        center.dy + 10 * scale,
      );

    canvas.drawPath(
      domePath,
      Paint()
        ..color = accentColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      domePath,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // ── Visor / brim ──
    final brimPath = Path()
      ..moveTo(center.dx - 44 * scale, center.dy + 10 * scale)
      ..lineTo(center.dx + 44 * scale, center.dy + 10 * scale);

    canvas.drawPath(
      brimPath,
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Sensor dot (center forehead) ──
    canvas.drawCircle(
      Offset(center.dx, center.dy - 20 * scale),
      4 * scale,
      Paint()..color = isConnected ? AppColors.accent : AppColors.textTertiary,
    );
    if (isConnected) {
      canvas.drawCircle(
        Offset(center.dx, center.dy - 20 * scale),
        8 * scale,
        Paint()..color = AppColors.accent.withValues(alpha: 0.2),
      );
    }

    // ── Signal waves (right side) ──
    if (isConnected) {
      for (int i = 0; i < 3; i++) {
        final waveRadius = (12 + i * 8) * scale;
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(center.dx + 25 * scale, center.dy - 10 * scale),
            radius: waveRadius,
          ),
          -pi / 3,
          pi / 3,
          false,
          Paint()
            ..color = accentColor.withValues(alpha: 0.5 - i * 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // ── Label beneath ──
    final labelStyle = TextStyle(
      color: AppColors.textTertiary,
      fontSize: 10 * scale,
      fontWeight: FontWeight.w600,
      letterSpacing: 2,
    );
    final tp = TextPainter(
      text: TextSpan(text: 'GUARDIAN', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy + 30 * scale),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_HelmetPainter old) =>
      old.isConnected != isConnected || old.tiltAngle != tiltAngle;
}
