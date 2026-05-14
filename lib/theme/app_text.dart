import 'package:flutter/material.dart';

//<3<3<3<3<3<3 Responsive text scaling <3<3<3<3<3<3<3
class Sp {
  static const double _ref = 390.0;

  static double s(BuildContext context, double size) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / _ref).clamp(0.90, 1.06);
    return size * scale;
  }
}

//<3<3<3<3<3<3<3<3 Text scale helper <3<3<3<3<3<3<3<3
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
}
