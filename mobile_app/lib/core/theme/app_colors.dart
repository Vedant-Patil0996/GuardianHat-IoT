import 'package:flutter/material.dart';

/// GuardianHat Design System — Color Tokens
///
/// Three-level surface hierarchy:
///   background → surface → surfaceElevated
///
/// Glass effects reserved ONLY for hero device card and fall alert overlay.
class AppColors {
  AppColors._();

  // ── Background & Surfaces ──
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceElevated = Color(0xFF263449);

  // ── Accent ──
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentMuted = Color(0xFF0E7490);
  static const Color accentSurface = Color(0x1A06B6D4); // 10% accent

  // ── Danger ──
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerMuted = Color(0xFF991B1B);
  static const Color dangerSurface = Color(0x1AEF4444); // 10% danger

  // ── Warning ──
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSurface = Color(0x1AF59E0B);

  // ── Success ──
  static const Color success = Color(0xFF22C55E);
  static const Color successSurface = Color(0x1A22C55E);

  // ── Text ──
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF475569);

  // ── Borders ──
  static const Color border = Color(0xFF334155);
  static const Color borderAccent = Color(0x3306B6D4); // 20% accent

  // ── Misc ──
  static const Color scrim = Color(0x99000000); // 60% black overlay
  static const Color shimmer = Color(0xFF334155);
}
