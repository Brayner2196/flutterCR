import 'package:flutter/material.dart';
import '../../../../../models/dashboard/pendientes_hoy.dart';
import '../dashboard/dashboard_tokens.dart';

/// Widget KPI de incidencias y PQRs pendientes.
/// Muestra los 3 tipos de pendientes del día (PQRs, comprobantes, reservas).
class KpiIncidenciasPqr extends StatelessWidget {
  final PendientesHoy data;
  final VoidCallback? onTapPqrs;
  final VoidCallback? onTapPagos;
  final VoidCallback? onTapReservas;

  const KpiIncidenciasPqr({
    super.key,
    required this.data,
    this.onTapPqrs,
    this.onTapPagos,
    this.onTapReservas,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
          Text(
            'INCIDENCIAS Y PQRS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // ── Contadores ───────────────────────────────
          Row(
            children: [
              _ContadorBox(
                label: 'RECIBIDAS',
                valor: data.pqrs,
                color: DashboardTokens.fgOrange,
                bgColor: DashboardTokens.bgOrange,
                onTap: onTapPqrs,
              ),
              const SizedBox(width: 8),
              _ContadorBox(
                label: 'PENDIENTES',
                valor: data.comprobantes,
                color: DashboardTokens.fgPurple,
                bgColor: DashboardTokens.bgPurple,
                onTap: onTapPagos,
              ),
              const SizedBox(width: 8),
              _ContadorBox(
                label: 'RESERVAS',
                valor: data.reservas,
                color: DashboardTokens.fgTeal,
                bgColor: DashboardTokens.bgTeal,
                onTap: onTapReservas,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Resumen total ────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.total > 0
                      ? DashboardTokens.bgOrange
                      : DashboardTokens.bgGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  data.total > 0
                      ? Icons.priority_high
                      : Icons.check_circle_outline,
                  color: data.total > 0
                      ? DashboardTokens.fgOrange
                      : DashboardTokens.fgGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.total > 0
                          ? '${data.total} pendiente${data.total == 1 ? '' : 's'} hoy'
                          : 'Todo al día',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _subtitulo(),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 14),

          // ── Barras proporcionales ────────────────────
          if (data.total > 0) ...[
            const Divider(height: 1),
            const SizedBox(height: 12),
            _BarritaPendiente(
              label: 'PQRs',
              valor: data.pqrs,
              total: data.total,
              color: DashboardTokens.fgOrange,
              bgColor: DashboardTokens.bgOrange,
              onTap: onTapPqrs,
            ),
            const SizedBox(height: 8),
            _BarritaPendiente(
              label: 'Comprobantes',
              valor: data.comprobantes,
              total: data.total,
              color: DashboardTokens.fgPurple,
              bgColor: DashboardTokens.bgPurple,
              onTap: onTapPagos,
            ),
            const SizedBox(height: 8),
            _BarritaPendiente(
              label: 'Reservas',
              valor: data.reservas,
              total: data.total,
              color: DashboardTokens.fgTeal,
              bgColor: DashboardTokens.bgTeal,
              onTap: onTapReservas,
            ),
          ],
        ],
      ),
    );
  }

  String _subtitulo() {
    final partes = <String>[];
    if (data.pqrs > 0) partes.add('${data.pqrs} PQR${data.pqrs == 1 ? '' : 's'}');
    if (data.comprobantes > 0) partes.add('${data.comprobantes} comprobante${data.comprobantes == 1 ? '' : 's'}');
    if (data.reservas > 0) partes.add('${data.reservas} reserva${data.reservas == 1 ? '' : 's'}');
    return partes.isEmpty ? 'Sin pendientes hoy' : partes.join(' · ');
  }
}

class _ContadorBox extends StatelessWidget {
  final String label;
  final int valor;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _ContadorBox({
    required this.label,
    required this.valor,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                '$valor',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarritaPendiente extends StatelessWidget {
  final String label;
  final int valor;
  final int total;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _BarritaPendiente({
    required this.label,
    required this.valor,
    required this.total,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fraccion = total > 0 ? valor / total : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraccion,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$valor',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
