import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/cobro_cobranza_model.dart';

/// Presentación única de la urgencia de un cobro en mora.
///
/// Color, icono y etiqueta viven aquí y no en cada widget: la tarjeta, el grid
/// de métricas y los filtros hablan del mismo concepto, y si "crítico" cambia
/// de color se cambia en un solo sitio.
class UrgenciaCobranzaUi {
  final String clave;
  final String label;
  final String plural;
  final Color color;
  final IconData icono;

  const UrgenciaCobranzaUi._({
    required this.clave,
    required this.label,
    required this.plural,
    required this.color,
    required this.icono,
  });

  static const porVencer = UrgenciaCobranzaUi._(
    clave: 'POR_VENCER',
    label: 'Por vencer',
    plural: 'Por vencer',
    color: AppColors.warning,
    icono: Icons.schedule,
  );

  static const vencido = UrgenciaCobranzaUi._(
    clave: 'VENCIDO',
    label: 'Vencido',
    plural: 'Vencidos',
    color: AppColors.danger,
    icono: Icons.error_outline,
  );

  static const mora = UrgenciaCobranzaUi._(
    clave: 'MORA',
    label: 'Con mora',
    plural: 'Con mora',
    color: AppColors.orange,
    icono: Icons.trending_up,
  );

  static const critico = UrgenciaCobranzaUi._(
    clave: 'CRITICO',
    label: 'Crítico',
    plural: 'Críticos',
    color: AppColors.purple,
    icono: Icons.gavel_outlined,
  );

  /// Urgencia con la que se pinta la tarjeta: la más grave que aplique.
  static UrgenciaCobranzaUi de(CobroCobranzaModel c, {int diasCritico = 30}) {
    if (c.diasVencido >= diasCritico) return critico;
    if (c.vencido) return vencido;
    return porVencer;
  }
}
