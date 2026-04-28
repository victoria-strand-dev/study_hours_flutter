import 'package:flutter/material.dart';
import 'app_colors.dart';

// ─── TEXT SCALE HELPER ────────────────────────────────────────────────────────
// Reference: 390dp (iPhone 14 / Pixel 7 logical width).
//
// Scale band: 0.96 – 1.01
//   360dp (1080px Android) → 0.96× (text ~4% smaller than base)
//   390dp                  → 1.00× (exact base)
//   414dp (1242px iPhone)  → 1.01× (barely 1% up — prevents overflow on large screens)
//
// Hard floor: result is never more than 1.5pt below base, so even on
// very compact screens the text stays legible.
// ─── SPACING / SIZE SCALE HELPER ─────────────────────────────────────────────
// Use for padding, gaps, fixed heights — not fonts (use Ts for fonts).
// Scale band: 0.90 – 1.06
//   360dp (1080px Android @ 3×) → 0.92×  → clamp floor 0.90×
//   390dp (reference)           → 1.00×
//   414dp (1242px iPhone @ 3×)  → 1.06×  → clamp ceiling 1.06×
//
// This gives proportionally identical layouts across devices:
//   360dp card content ≈ 87% of 414dp content width (mirrors actual screen ratio)
class Sp {
  static const double _ref = 390.0;

  static double s(BuildContext context, double size) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / _ref).clamp(0.90, 1.06);
    return size * scale;
  }
}

// ─── TEXT SCALE HELPER ────────────────────────────────────────────────────────
// Reference: 390dp (iPhone 14 / Pixel 7 logical width).
//
// Scale band: 1.00 – 1.04
//   ≤390dp  → 1.00× (text never shrinks below base — readability floor)
//   414dp   → 1.04× (modest up-scale for large screens)
//
// Hard floor: result is never more than 1.5pt below base.
class Ts {
  static const double _ref = 390.0;

  static double s(BuildContext context, double size) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / _ref).clamp(1.0, 1.04);
    final scaled = size * scale;
    final floor = size - 1.5;
    return scaled < floor ? floor : scaled;
  }
}

class AppText {
  static const TextStyle screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: AppColors.textDark,
    letterSpacing: 1.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  );

  static const TextStyle cardTitleLight = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const TextStyle bodyLight = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle bodyDark = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle smallLight = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white70,
  );

  static const TextStyle smallDark = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static const TextStyle tinyLight = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white60,
  );

  static const TextStyle tinyDark = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
}