import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/connection_state.dart';

/// Pulsing status indicator dot with label.
///
/// Visual states:
/// - LIVE: pulsing cyan dot (slow breathe animation)
/// - RECONNECTING: pulsing amber dot
/// - OFFLINE: static grey dot
class LiveIndicator extends StatefulWidget {
  final DeviceConnectionState state;

  const LiveIndicator({super.key, required this.state});

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(LiveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.state == DeviceConnectionState.live) {
      _controller.repeat(reverse: true);
    } else if (widget.state == DeviceConnectionState.reconnecting) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  Color get _dotColor {
    switch (widget.state) {
      case DeviceConnectionState.live:
        return AppColors.accent;
      case DeviceConnectionState.reconnecting:
        return AppColors.warning;
      case DeviceConnectionState.offline:
        return AppColors.textTertiary;
    }
  }

  String get _label {
    switch (widget.state) {
      case DeviceConnectionState.live:
        return 'LIVE';
      case DeviceConnectionState.reconnecting:
        return 'RECONNECTING';
      case DeviceConnectionState.offline:
        return 'OFFLINE';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dotColor.withValues(alpha: _pulse.value),
                boxShadow: widget.state != DeviceConnectionState.offline
                    ? [
                        BoxShadow(
                          color: _dotColor.withValues(alpha: 0.4 * _pulse.value),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            );
          },
        ),
        const SizedBox(width: 6),
        Text(
          _label,
          style: AppTextStyles.labelSmall.copyWith(
            color: _dotColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
