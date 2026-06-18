import 'package:flutter/material.dart';
import '../utils/estado_cobro_ui.dart';
import '../../../shared/theme/app_theme.dart';

/// Cuadrícula 2x2 con el conteo de cobros por estado (Vencidos, Pendientes,
/// Parciales, Pagados). Cada tarjeta actúa como filtro: al tocarla filtra la
/// lista por ese estado; al volver a tocarla, limpia el filtro.
///
/// Sustituye a los `FiltroChips` en la pestaña de Cobros (rediseño).
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
            _celda(context, _orden[0]),
            const SizedBox(width: 10),
            _celda(context, _orden[1]),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _celda(context, _orden[2]),
            const SizedBox(width: 10),
            _celda(context, _orden[3]),
          ]),
        ],
      ),
    );
  }

  Widget _celda(BuildContext context, String codigo) {
    final ui = EstadoCobroUi.de(codigo);
    final count = counts[codigo] ?? 0;
    return Expanded(
      child: _EstadoCard(
        ui: ui,
        etiqueta: _plural[codigo] ?? ui.label,
        count: count,
        seleccionado: seleccionado == codigo,
        // VENCIDO con casos resalta su borde aunque no esté seleccionado.
        alerta: codigo == 'VENCIDO' && count > 0,
        onTap: () => onSeleccionar(seleccionado == codigo ? null : codigo),
      ),
    );
  }
}

class _EstadoCard extends StatelessWidget {
  final EstadoCobroUi ui;
  final String etiqueta;
  final int count;
  final bool seleccionado;
  final bool alerta;
  final VoidCallback onTap;

  const _EstadoCard({
    required this.ui,
    required this.etiqueta,
    required this.count,
    required this.seleccionado,
    required this.alerta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bordeColor = seleccionado
        ? ui.color
        : alerta
            ? ui.color.withValues(alpha: 0.5)
            : cs.outline;
    return Material(
      color: seleccionado ? ui.color.withValues(alpha: 0.08) : cs.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: bordeColor,
              width: seleccionado ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ui.color,
                    ),
                  ),
                  const Spacer(),
                  Icon(ui.icono, size: 18, color: ui.color),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
