import 'package:flutter/material.dart';

class AppColors {
  // ── Scaffold background ───────────────────────────────────────────────────
  static const Color bg          = Color(0xFFAED8F0); // Sky blue — you can match logo bg to this

  // ── Blue card system — from logo figure colors ────────────────────────────
  static const Color card        = Color(0xFF46BEFF); // Logo blue #46BEFF
  static const Color cardDark    = Color(0xFF2E82C8); // Adjusted dark blue
  static const Color cardDeep    = Color(0xFF3D6899); // Logo dark navy #3D6899

  // ── Surface (white) ── used sparingly for selected/focus states ───────────
  static const Color surface     = Color(0xFFFFFFFF); // White — "selected" pop
  static const Color surfaceAlt  = Color(0xFFEFF7FD); // Very light blue-white

  // ── Text on blue cards ────────────────────────────────────────────────────
  static const Color white       = Colors.white;
  static const Color textDark    = Color(0xFF3D6899); // Logo dark navy — text on bg
  static const Color onSurface   = Color(0xFF1A3A5C); // Text on white surface
  static const Color onSurfaceMid = Color(0xFF5B7A9B); // Muted text on white

  // ── Accent — orange CTA — from logo beak color ───────────────────────────
  static const Color accent      = Color(0xFFFFB15D); // Logo orange #FFB15D

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success     = Color(0xFF2ECC71);
  static const Color warning     = Color(0xFFF39C12);
  static const Color danger      = Color(0xFFC0392B);

  // ── Borders ───────────────────────────────────────────────────────────────
  // cardBorder: subtle white on blue cards — not cyan (cyan clashes when
  // card and border share similar hue but different lightness)
  static const Color border      = Color(0x28FFFFFF); // white 16% — on blue cards
  static const Color cardBorder  = Color(0x28FFFFFF);
  static const Color surfaceBorder = Color(0xFFD0E8F8); // on white/light surfaces
  static const Color primaryLight  = Color(0xFFCCE8FF);
  static const Color inputBg     = Color(0xFFCCEAF8);

  static Color gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A': return const Color(0xFF2ECC71);
      case 'B': return const Color(0xFF27AE60);
      case 'C': return const Color(0xFFF39C12);
      case 'D': return const Color(0xFFE67E22);
      case 'E': return const Color(0xFFE74C3C);
      default:  return const Color(0xFFC0392B);
    }
  }
}
