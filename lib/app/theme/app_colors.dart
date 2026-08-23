import 'package:flutter/material.dart';

/// Professional trading application color palette inspired by Zerodha & Groww
class AppColors {
  AppColors._();

  // Primary backgrounds
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceElevated = Color(0xFF21262D);
  static const Color surfaceHighlight = Color(0xFF30363D);

  // Market indicators
  static const Color green = Color(0xFF00C087);      // Bullish / Profit
  static const Color greenLight = Color(0x2600C087); // Subtle green highlight (15% opacity)
  static const Color greenFlash = Color(0x4000C087); // Distinct 25% opacity for price cell flash
  static const Color red = Color(0xFFFF4D4F);        // Bearish / Loss
  static const Color redLight = Color(0x26FF4D4F);   // Subtle red highlight (15% opacity)
  static const Color redFlash = Color(0x40FF4D4F);   // Distinct 25% opacity for price cell flash

  // Brand & Accents
  static const Color primary = Color(0xFF2F80ED);
  static const Color primaryDark = Color(0xFF1B59B3);
  static const Color accent = Color(0xFF38EF7D);

  // Typography
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF6E7681);

  // Borders & Dividers
  static const Color border = Color(0xFF30363D);
  static const Color divider = Color(0xFF21262D);

  // Status badges
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
}
