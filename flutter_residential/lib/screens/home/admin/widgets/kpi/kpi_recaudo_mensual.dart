import 'package:flutter/material.dart';
import '../../../../../models/dashboard/recaudo_mes.dart';
import '../dashboard/dashboard_tokens.dart';

/// Widget KPI de recaudo mensual con desglose de pagos.
/// Equivalente visual al mockup: monto total, % meta, variación y breakdown.
class KpiRecaudoMensual extends StatelessWidget {
  final RecaudoMes data;
  final String nombreMes;

  const KpiRecaudoMensual({
    super.key,
    required this.data,
    required this.nombreMes,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final recaudadoMes =
        (data.recaudado - data.recaudadoCobrosViejos).clamp(0.0, double.infinity);
    final pendiente =
        (data.esperado - data.recaudado).clamp(0.0, double.infinity);
    final base = data.esperado > 0 ? data.esperado : 1.0;
    final diasEnMes = DateTime(data.anio, data.mes + 1, 0).day;
    final diaActual = DateTime.now().day.clamp(1, diasEnMes);

    final pctMes = ((recaudadoMes / base) * 100).round().clamp(0, 100);
    final pctAtrasados =
        ((data.recaudadoCobrosViejos / base) * 100).round().clamp(0, 100);
    final pctPendiente = ((pendiente / base) * 100).round().clamp(0, 100);
    final positivo = data.puntosVariacion >= 0;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(DashboardTokens.radiusCard),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECAUDO · ${nombreMes.toUpperCase()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                'Día $diaActual/$diasEnMes',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Monto grande centrado ────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  'RECAUDADO',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.0,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatoMillones(data.recaudado),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: DashboardTokens.bgGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        positivo
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 12,
                        color: DashboardTokens.fgGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${data.porcentaje}% de la meta  ·  '
                        '${positivo ? '+' : ''}${data.puntosVariacion} pts vs mes ant.',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: DashboardTokens.fgGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Desglose ────────────────────────────────
          _FilaDesglose(
            color: DashboardTokens.fgGreen,
            label: 'Pagos del mes (al día)',
            porcentaje: pctMes,
            monto: formatoMillones(recaudadoMes),
          ),
          const SizedBox(height: 8),
          _FilaDesglose(
            color: DashboardTokens.fgYellow,
            label: 'Pagos atrasados al corriente',
            porcentaje: pctAtrasados,
            monto: formatoMillones(data.recaudadoCobrosViejos),
          ),
          const SizedBox(height: 8),
          _FilaDesglose(
            color: cs.onSurfaceVariant,
            label: 'Pendiente para cumplir meta',
            porcentaje: pctPendiente,
            monto: formatoMillones(pendiente),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // ── Meta ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'META',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                formatoMillones(data.esperado),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaDesglose extends StatelessWidget {
  final Color color;
  final String label;
  final int porcentaje;
  final String monto;

  const _FilaDesglose({
    required this.color,
    required this.label,
    required this.porcentaje,
    required this.monto,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$porcentaje%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 64,
          child: Text(
            monto,
            textAlign: TextAlign.end,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
