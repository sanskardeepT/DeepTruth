import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── PRIMARY PALETTE ──
  static const Color primary      = Color(0xFF0A0E27);
  static const Color primaryLight = Color(0xFF141830);
  static const Color accent       = Color(0xFF00D4FF);
  static const Color accentDark   = Color(0xFF0099BB);

  // ── TRUTH SCORE COLORS ──
  static const Color truthTrue    = Color(0xFF00FF88);
  static const Color truthMostly = Color(0xFF7FFF00);
  static const Color truthMixed  = Color(0xFFFFB800);
  static const Color truthFalse  = Color(0xFFFF6B35);
  static const Color truthFake   = Color(0xFFFF4757);
  static const Color truthUnknown= Color(0xFF8B8FA8);

  // ── BACKGROUNDS ──
  static const Color bgPrimary   = Color(0xFF0A0E27);
  static const Color bgSecondary = Color(0xFF141830);
  static const Color bgCard      = Color(0xFF1E2240);
  static const Color bgCardHover = Color(0xFF252B4A);
  static const Color bgInput     = Color(0xFF1A1E38);

  // ── TEXT ──
  static const Color textPrimary   = Color(0xFFF8F9FF);
  static const Color textSecondary = Color(0xFFB0B8D1);
  static const Color textMuted     = Color(0xFF6B7280);
  static const Color textAccent    = Color(0xFF00D4FF);

  // ── SEMANTIC ──
  static const Color danger  = Color(0xFFFF4757);
  static const Color warning = Color(0xFFFFB800);
  static const Color success = Color(0xFF00FF88);
  static const Color info    = Color(0xFF00D4FF);
  static const Color divider = Color(0xFF2A2F50);

  static Color scoreColor(int score) {
    if (score >= 81) return truthTrue;
    if (score >= 61) return truthMostly;
    if (score >= 41) return truthMixed;
    if (score >= 21) return truthFalse;
    return truthFake;
  }
}
