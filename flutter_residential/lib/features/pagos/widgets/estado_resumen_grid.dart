import 'package:flutter/material.dart';
import '../utils/estado_cobro_ui.dart';
import '../../../shared/widgets/metrica_card.dart';

/// Cuadrícula 2x2 con el conteo de cobros por estado (Vencidos, Pendientes,
/// Parciales, Pagados). Cada tarjeta actúa como filtro: al tocarla filtra la
/// lista por ese estado; al volver a tocarla, limpia el filtro.
///
/// La celda es `MetricaCard` (shared): la misma pieza que usa el grid de
/// cobranza, que cuenta otras cosas.
class EstadoResumenGrid extends StatelessWidget {
  /// Conteo por código de estado (PENDIENTE, PARCIAL, VENCIDO, PAGADO...).
  final Map<String, int> counts;

  /// Estado actualmente seleccionado (filtro activo). `null` = sin filtro.
  final String? seleccionado;
  final ValueChanged<String?> onSeleccionar;

  const EstadoResumenGrid({
    super.key,
    required this.counts,
    required this.seleccionado,
    required this.onSeleccionar,
  });

  /// Estados destacados en el grid, en orden de lectura (alertas primero).
  static const _orden = ['VENCIDO', 'PENDIENTE', 'PARCIAL', 'PAGADO'];

  /// Etiquetas en plural para el grid (el badge usa el singular).
  static const _plural = {
    'VENCIDO': 'Vencidos',
    'PENDIENTE': 'Pendientes',
    'PARCIAL': 'Parciales',
    'PAGADO': 'Pagados',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        children: [
          Row(children: [
            _celda(_orden[0]),
            const SizedBox(width: 10),
            _celda(_orden[1]),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _celda(_orden[2]),
            const SizedBox(width: 10),
            _celda(_orden[3]),
          ]),
        ],
      ),
    );
  }

  Widget _celda(String codigo) {
    final ui = EstadoCobroUi.de(codigo);
    final count = counts[codigo] ?? 0;
    return Expanded(
      child: MetricaCard(
        valor: count,
        etiqueta: _plural[codigo] ?? ui.label,
        icono: ui.icono,
        color: ui.color,
        seleccionado: seleccionado == codigo,
        // VENCIDO con casos resalta su borde aunque no esté seleccionado.
        alerta: codigo == 'VENCIDO' && count > 0,
        onTap: () => onSeleccionar(seleccionado == codigo ? null : codigo),
      ),
    );
  }
}
