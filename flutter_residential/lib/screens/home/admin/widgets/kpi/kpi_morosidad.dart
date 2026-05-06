import 'package:flutter/material.dart';
import '../../../../../models/dashboard/cartera_vencida.dart';
import '../../../../../models/dashboard/estado_unidades.dart';
import '../dashboard/dashboard_tokens.dart';

/// Widget KPI de morosidad: muestra % mora, monto total y distribución
/// de unidades (al día / por vencer / en mora) con barras de progreso.
class KpiMorosidad extends StatelessWidget {
  final CarteraVencida cartera;
  final EstadoUnidades unidades;

  const KpiMorosidad({
    super.key,
    required this.cartera,
    required this.unidades,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = unidades.total > 0 ? unidades.total : 1;
    final pct = ((cartera.unidadesEnMora / total) * 100).round();
    final positivo = cartera.variacionMonto >= 0;

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
                'MOROSIDAD POR ANTIGÜEDAD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DashboardTokens.bgRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${cartera.unidadesEnMora}/${unidades.total}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DashboardTokens.fgRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Porcentaje + monto ───────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pct%',
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: DashboardTokens.fgRed,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '${formatoMillones(cartera.monto)} en mora',
                  style: const TextStyle(
                    fontSize: 13,
                    color: DashboardTokens.fgRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Variación ────────────────────────────────
          Row(
            children: [
              Icon(
                positivo ? Icons.trending_up : Icons.trending_down,
                size: 13,
                // Si sube la cartera vencida es malo (rojo), si baja es bueno (verde)
                color: positivo
                    ? DashboardTokens.fgRed
                    : DashboardTokens.fgGreen,
              ),
              const SizedBox(width: 4),
              Text(
                '${positivo ? '+' : '-'}${formatoMillones(cartera.variacionMonto.abs())} vs mes anterior',
                style:
                    TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Barras de distribución ───────────────────
          _BarraEstado(
            label: 'Al día',
            cantidad: unidades.alDia,
            total: unidades.total,
            color: DashboardTokens.fgGreen,
            bgColor: DashboardTokens.bgGreen,
          ),
          const SizedBox(height: 10),
          _BarraEstado(
            label: 'Por vencer',
            cantidad: unidades.porVencer,
            total: unidades.total,
            color: DashboardTokens.fgYellow,
            bgColor: DashboardTokens.bgYellow,
          ),
          const SizedBox(height: 10),
          _BarraEstado(
            label: 'En mora',
            cantidad: unidades.enMora,
            total: unidades.total,
            color: DashboardTokens.fgRed,
            bgColor: DashboardTokens.bgRed,
          ),
          const SizedBox(height: 14),

          // ── Barra segmentada total ───────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (unidades.alDia > 0)
                    Expanded(
                      flex: unidades.alDia,
                      child: Container(color: DashboardTokens.fgGreen),
                    ),
                  if (unidades.porVencer > 0)
                    Expanded(
                      flex: unidades.porVencer,
                      child: Container(color: DashboardTokens.fgYellow),
                    ),
                  if (unidades.enMora > 0)
                    Expanded(
                      flex: unidades.enMora,
                      child: Container(color: DashboardTokens.fgRed),
                    ),
                  if (unidades.alDia + unidades.porVencer + unidades.enMora ==
                      0)
                    Expanded(
                      flex: 1,
                      child: Container(color: cs.outlineVariant),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraEstado extends StatelessWidget {
  final String label;
  final int cantidad;
  final int total;
  final Color color;
  final Color bgColor;

  const _BarraEstado({
    required this.label,
    required this.cantidad,
    required this.total,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valor = total > 0 ? cantidad / total : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: valor,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '${(valor * 100).round()}%',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$cantidad',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
