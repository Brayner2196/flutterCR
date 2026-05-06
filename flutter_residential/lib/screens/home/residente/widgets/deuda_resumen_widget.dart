import 'package:flutter/material.dart';
import '../../../../models/residente_estadisticas_model.dart';

/// Widget coloquial que muestra el resumen de deuda del residente
/// de manera simple y natural en el home. Reemplaza los KPI cards técnicos.
class DeudaResumenWidget extends StatelessWidget {
  final ResidenteEstadisticasModel stats;
  final String Function(double) formatMonto;
  final VoidCallback onVerEstadoCuenta;

  const DeudaResumenWidget({
    super.key,
    required this.stats,
    required this.formatMonto,
    required this.onVerEstadoCuenta,
  });

  @override
  Widget build(BuildContext context) {
    return stats.alDia ? _buildAlDia(context) : _buildConDeuda(context);
  }

  // ─── Estado al día ────────────────────────────────────────────────────────

  Widget _buildAlDia(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Todo al día! 🎉',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'No tienes cobros pendientes por el momento.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Estado con deuda ─────────────────────────────────────────────────────

  Widget _buildConDeuda(BuildContext context) {
    final tieneVencidos = stats.cobrosVencidos > 0;
    final color = tieneVencidos ? Colors.red : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ──
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                'Tu situación financiera',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const Spacer(),
              if (tieneVencidos) _badgeMora(),
            ],
          ),
          const SizedBox(height: 10),

          // ── Monto principal ──
          Text(
            'Debes ${formatMonto(stats.totalDeuda)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'en total por pagar',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // ── Desglose coloquial ──
          if (stats.cobrosVencidos > 0)
            _linea(
              icon: Icons.warning_amber_rounded,
              color: Colors.red,
              texto: stats.cobrosVencidos == 1
                  ? '1 cobro vencido sin pagar'
                  : '${stats.cobrosVencidos} cobros vencidos sin pagar',
              monto: formatMonto(stats.totalVencido),
            ),
          if (stats.cobrosVencidos > 0 && stats.cobrosPendientes > 0)
            const SizedBox(height: 10),
          if (stats.cobrosPendientes > 0)
            _linea(
              icon: Icons.schedule_rounded,
              color: Colors.orange,
              texto: stats.cobrosPendientes == 1
                  ? '1 cobro pendiente del mes'
                  : '${stats.cobrosPendientes} cobros pendientes del mes',
              monto: formatMonto(stats.totalPendiente),
            ),
          if (stats.totalMora > 0) ...[
            const SizedBox(height: 10),
            _linea(
              icon: Icons.add_circle_outline,
              color: Colors.red.shade300,
              texto: 'Recargos por mora incluidos',
              monto: formatMonto(stats.totalMora),
              italica: true,
            ),
          ],

          const SizedBox(height: 18),

          // ── CTA ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onVerEstadoCuenta,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: const Text('Ver estado de cuenta'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Widgets auxiliares ───────────────────────────────────────────────────

  Widget _badgeMora() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 12),
          SizedBox(width: 3),
          Text(
            'En mora',
            style: TextStyle(
              color: Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _linea({
    required IconData icon,
    required Color color,
    required String texto,
    required String monto,
    bool italica = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontStyle: italica ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
        Text(
          monto,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
