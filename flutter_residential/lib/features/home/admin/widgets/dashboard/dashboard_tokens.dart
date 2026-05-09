import 'package:flutter/material.dart';

/// Paleta específica del dashboard de KPIs (pasteles suaves + acentos).
class DashboardTokens {
  DashboardTokens._();

  static const bgGreen = Color.fromRGBO(229, 245, 233, 1);
  static const fgGreen = Color.fromRGBO(28, 96, 47, 1);

  static const bgOrange = Color.fromRGBO(255, 233, 219, 1);
  static const fgOrange = Color.fromRGBO(180, 70, 0, 1);

  static const bgPurple = Color.fromRGBO(238, 226, 248, 1);
  static const fgPurple = Color.fromRGBO(96, 36, 144, 1);

  static const bgTeal = Color.fromRGBO(224, 247, 244, 1);
  static const fgTeal = Color.fromRGBO(0, 105, 92, 1);

  static const bgRed = Color.fromRGBO(255, 234, 230, 1);
  static const fgRed = Color.fromRGBO(176, 50, 40, 1);

  static const bgYellow = Color.fromRGBO(255, 244, 200, 1);
  static const fgYellow = Color.fromRGBO(140, 105, 0, 1);

  static const radiusCard = 16.0;
  static const paddingCard = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
}

String formatoMillones(double monto) {
  if (monto.abs() >= 1000000) {
    return '\$ ${(monto / 1000000).toStringAsFixed(1)}M';
  }
  if (monto.abs() >= 1000) {
    return '\$ ${(monto / 1000).toStringAsFixed(0)}K';
  }
  return '\$ ${monto.toStringAsFixed(0)}';
}
