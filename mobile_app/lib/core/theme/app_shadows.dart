import 'package:flutter/material.dart';
import 'app_colors.dart';

/// GuardianHat Design System — Shadow & Glow Tokens
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glow => [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.15),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get dangerGlow => [
        BoxShadow(
          color: AppColors.danger.withValues(alpha: 0.25),
          blurRadius: 24,
          spreadRadius: 0,
        ),
      ];
}
