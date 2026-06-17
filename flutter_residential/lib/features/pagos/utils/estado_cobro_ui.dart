import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

/// Mapeo único de presentación para los estados de un cobro.
///
/// Centraliza color / etiqueta / icono por estado y elimina los ternarios
/// y mapas duplicados que estaban repetidos en cada pantalla de pagos.
/// Refleja el enum `EstadoCobro` del backend:
/// PENDIENTE, EN_VERIFICACION, PARCIAL, PAGADO, VENCIDO, EXONERADO.
class EstadoCobroUi {
  final String codigo;
  final String label;
  final Color color;
  final IconData icono;

  const EstadoCobroUi._({
    required this.codigo,
    required this.label,
    required this.color,
    required this.icono,
  });

  static const _desconocido = EstadoCobroUi._(
    codigo: '',
    label: 'Otro',
    color: AppColors.neutralSoft,
    icono: Icons.help_outline,
  );

  static const Map<String, EstadoCobroUi> _mapa = {
    'PENDIENTE': EstadoCobroUi._(
      codigo: 'PENDIENTE',
      label: 'Pendiente',
      color: AppColors.warning,
      icono: Icons.schedule,
    ),
    'EN_VERIFICACION': EstadoCobroUi._(
      codigo: 'EN_VERIFICACION',
      label: 'En verificación',
      color: AppColors.blue,
      icono: Icons.hourglass_top,
    ),
    'PARCIAL': EstadoCobroUi._(
      codigo: 'PARCIAL',
      label: 'Parcial',
      color: AppColors.orange,
      icono: Icons.incomplete_circle,
    ),
    'PAGADO': EstadoCobroUi._(
      codigo: 'PAGADO',
      label: 'Pagado',
      color: AppColors.ok,
      icono: Icons.check_circle,
    ),
    'VENCIDO': EstadoCobroUi._(
      codigo: 'VENCIDO',
      label: 'Vencido',
      color: AppColors.danger,
      icono: Icons.error_outline,
    ),
    'EXONERADO': EstadoCobroUi._(
      codigo: 'EXONERADO',
      label: 'Exonerado',
      color: AppColors.purple,
      icono: Icons.remove_circle_outline,
    ),
  };

  /// Resuelve la presentación de un estado. Nunca lanza: devuelve un
  /// valor neutro si el estado no es conocido (degradación segura).
  static EstadoCobroUi de(String? estado) =>
      _mapa[estado] ?? _desconocido;

  /// Orden de aparición de estados en filtros/leyendas.
  static const List<String> orden = [
    'PENDIENTE',
    'EN_VERIFICACION',
    'PARCIAL',
    'VENCIDO',
    'PAGADO',
    'EXONERADO',
  ];

  /// Lista ordenada de presentaciones (útil para construir leyendas).
  static List<EstadoCobroUi> get todos =>
      orden.map((e) => _mapa[e]!).toList();
}
