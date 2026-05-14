import 'package:flutter/material.dart';

class AppColors {
  static const Color bg =
      Color(0xFFAED8F0); 

  static const Color accent = Color(0xFFFFB15D); 
  static const Color success = Color(0xFF2ECC71);

  //<3<3<3<3 Blue card system — from logo figure colors <3<3<3<3
  static const Color card = Color(0xFF46BEFF); 
  static const Color cardDark = Color(0xFF2E82C8); 
  static const Color cardDeep = Color(0xFF3D6899); 

  static const Color surface = Color(0xFFFFFFFF); // White — "selected" pop
  static const Color surfaceAlt = Color(0xFFEFF7FD); // Very light blue-white

  //<3<3<3<3<3<3<3<3<3<3<3<3 Text colors <3<3<3<3<3<3<3<3<3<3<3<3
  static const Color textDark =
      Color(0xFF3D6899); 
  static const Color onSurface = Color(0xFF1A3A5C); 
  static const Color onSurfaceMid = Color(0xFF5B7A9B); 

  //<3<3<3<3<3<3<3<3<3<3 Borders and inputs <3<3<3<3<3<3<3><3<3<3
  static const Color surfaceBorder = Color(0xFFD0E8F8);
  static const Color inputBg = Color(0xFFCCEAF8);

  static Color gradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return const Color(0xFF2ECC71);
      case 'B':
        return const Color(0xFF27AE60);
      case 'C':
        return const Color(0xFFF39C12);
      case 'D':
        return const Color(0xFFE67E22);
      case 'E':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFFC0392B);
    }
  }
}
