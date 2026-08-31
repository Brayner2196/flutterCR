import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/simular_abono_model.dart';

/// Muestra cómo se va a repartir una plata entre los cobros pendientes.
///
/// Es la pieza que hace entendible el reparto FIFO: sin verlo, el residente pone un
/// monto y recibe de vuelta un estado de cuenta que cambió de formas que no esperaba
/// ("pagué la cuota de agosto y me la aplicaron a la de mayo"). Con la lista delante,
/// la decisión la toma él antes de pagar, no el sistema después.
///
/// La usan la pantalla de confirmación del pago de deuda y la de registrar un abono
/// con comprobante: en ambos casos el residente necesita ver exactamente lo mismo.
class DistribucionFifoView extends StatelessWidget {
  final SimularAbonoModel simulacion;

  /// Encabezado del bloque. Cambia según desde dónde se mire el mismo reparto.
  final String titulo;

  const DistribucionFifoView({
    super.key,
    required this.simulacion,
    this.titulo = 'Distribución del pago',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sim = simulacion;

    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ),
            ],
          ),

          // El saldo a favor entra al pozo antes de repartir: si no se dice, el residente
          // no entiende por qué su pago alcanzó para más de lo que puso.
          if (sim.saldoFavorPrevio > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Saldo a favor previo: ${CurrencyFormatter.cop(sim.saldoFavorPrevio)}'
              '  →  Total disponible: ${CurrencyFormatter.cop(sim.totalDisponible)}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],

          const SizedBox(height: 10),

          if (sim.distribucion.isEmpty)
            Text(
              'No hay cobros pendientes por cubrir.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            )
          else
            ...sim.distribucion.map(
              (m) => _FilaDistribucion(
                descripcion: m.descripcion,
                monto: m.montoAplicado,
                esSaldoFavor: m.esSaldoFavor,
              ),
            ),

          if (sim.saldoFavorResultante > 0) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Queda a tu favor',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                Text(
                  CurrencyFormatter.cop(sim.saldoFavorResultante),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaDistribucion extends StatelessWidget {
  final String descripcion;
  final double monto;
  final bool esSaldoFavor;

  const _FilaDistribucion({
    required this.descripcion,
    required this.monto,
    required this.esSaldoFavor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            esSaldoFavor ? Icons.savings_outlined : Icons.check_circle_outline,
            size: 16,
            color: esSaldoFavor ? Colors.teal : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(descripcion, style: const TextStyle(fontSize: 13)),
          ),
          Text(
            CurrencyFormatter.cop(monto),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
