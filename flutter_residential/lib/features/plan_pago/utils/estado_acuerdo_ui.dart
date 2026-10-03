import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

/// Presentación del estado de un acuerdo de pago. La comparten la pantalla de
/// detalle y el PDF para que los dos pinten el estado con los mismos colores.
class EstadoAcuerdoUi {
  EstadoAcuerdoUi._();

  /// (fondo, texto) del chip de estado.
  static (Color, Color) colores(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return (AppColors.bgBlue, AppColors.blue);
      case 'COMPLETADO':
        return (AppColors.bgGreen, AppColors.ok);
      case 'RECHAZADO':
      case 'CANCELADO':
        return (AppColors.dangerSoft, AppColors.danger);
      default:
        return (AppColors.warningSoft, AppColors.warning);
    }
  }
}
