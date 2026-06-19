import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/movimiento_cobro_model.dart';
import 'pasarela_logo_widget.dart';

/// Línea de tiempo de la trazabilidad de un cobro: pagos directos y abonos
/// distribuidos, del más reciente al más antiguo. Opcionalmente cierra con
/// una entrada sintética "Cobro generado" (la creación del cobro).
///
/// Reutilizable: admin (detalle de cobro) y residente (estado de cuenta).
class MovimientoTimeline extends StatelessWidget {
  final List<MovimientoCobroModel> movimientos;

  /// Si se provee, agrega al final (entrada más antigua) la creación del cobro.
  final String? generadoLabel;
  final String? generadoFecha;
  final double? generadoMonto;

  const MovimientoTimeline({
    super.key,
    required this.movimientos,
    this.generadoLabel,
    this.generadoFecha,
    this.generadoMonto,
  });

  bool get _tieneGenerado => generadoLabel != null && generadoMonto != null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (movimientos.isEmpty && !_tieneGenerado) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('Sin movimientos registrados',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < movimientos.length; i++)
          _FilaMovimiento(
            mov: movimientos[i],
            esUltimo: !_tieneGenerado && i == movimientos.length - 1,
          ),
        if (_tieneGenerado)
          _FilaGenerado(
            label: generadoLabel!,
            fecha: generadoFecha,
            monto: generadoMonto!,
            esUltimo: true,
          ),
      ],
    );
  }
}

/// Riel izquierdo: punto de color + línea conectora (salvo el último).
class _Rail extends StatelessWidget {
  final Color color;
  final bool esUltimo;
  const _Rail({required this.color, required this.esUltimo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 4),
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        if (!esUltimo)
          Container(
            width: 1.5,
            height: 34,
            margin: const EdgeInsets.symmetric(vertical: 3),
            color: cs.outlineVariant,
          ),
      ],
    );
  }
}

class _FilaMovimiento extends StatelessWidget {
  final MovimientoCobroModel mov;
  final bool esUltimo;
  const _FilaMovimiento({required this.mov, required this.esUltimo});

  Color get _color => mov.esVerificado
      ? AppColors.ok
      : mov.esRechazado
          ? AppColors.danger
          : AppColors.warning;

  String get _estadoTexto => mov.esVerificado
      ? 'Verificado'
      : mov.esRechazado
          ? 'Rechazado'
          : 'Pendiente';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titulo = mov.esPago ? 'Pago' : 'Abono';
    final metodo = mov.metodoPago != null
        ? ' · ${MetodoPagoIcon.nombreLegible(mov.metodoPago)}'
        : '';
    final fecha = mov.creadoEn ?? mov.fecha;
    return Padding(
      padding: EdgeInsets.only(bottom: esUltimo ? 0 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Rail(color: _color, esUltimo: esUltimo),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MetodoPagoIcon(metodoPago: mov.metodoPago, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$titulo$metodo',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${CurrencyFormatter.cop(mov.monto)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: mov.esVerificado ? AppColors.ok : cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _estadoTexto,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _color,
                        ),
                      ),
                    ),
                    if (fecha != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          DateFormatter.fechaHoraMinAmPm(fecha),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ],
                ),
                if (mov.referencia != null && mov.referencia!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Ref: ${mov.referencia}',
                      style: TextStyle(
                          fontSize: 10, color: cs.onSurfaceVariant),
                    ),
                  ),
                if (mov.motivoRechazo != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      mov.motivoRechazo!,
                      style: const TextStyle(fontSize: 10, color: AppColors.danger),
                    ),
                  ),
                SizedBox(height: esUltimo ? 0 : 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaGenerado extends StatelessWidget {
  final String label;
  final String? fecha;
  final double monto;
  final bool esUltimo;
  const _FilaGenerado({
    required this.label,
    required this.fecha,
    required this.monto,
    required this.esUltimo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Rail(color: AppColors.blue, esUltimo: esUltimo),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.cop(monto),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              if (fecha != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 24),
                  child: Text(
                    DateFormatter.fechaCorta(fecha),
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
