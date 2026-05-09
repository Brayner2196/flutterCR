import 'package:flutter/material.dart';

/// Card que muestra un resumen de pagos con barras de progreso por estado.
class ResumenPagosCard extends StatelessWidget {
  final int verificados;
  final int pendientes;
  final int rechazados;
  final String? metodoFavorito;

  const ResumenPagosCard({
    super.key,
    required this.verificados,
    required this.pendientes,
    required this.rechazados,
    this.metodoFavorito,
  });

  int get total => verificados + pendientes + rechazados;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 18, color: Colors.blueGrey),
              const SizedBox(width: 8),
              const Text(
                'Resumen de pagos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '$total total${total != 1 ? 'es' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Barra de progreso segmentada
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (verificados > 0)
                      Flexible(
                        flex: verificados,
                        child: Container(color: Colors.green),
                      ),
                    if (pendientes > 0)
                      Flexible(
                        flex: pendientes,
                        child: Container(color: Colors.orange),
                      ),
                    if (rechazados > 0)
                      Flexible(
                        flex: rechazados,
                        child: Container(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Leyenda
          Row(
            children: [
              _leyenda('Verificados', verificados, Colors.green),
              const SizedBox(width: 16),
              _leyenda('Pendientes', pendientes, Colors.orange),
              const SizedBox(width: 16),
              _leyenda('Rechazados', rechazados, Colors.red),
            ],
          ),
          if (metodoFavorito != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.credit_card,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  'Método más usado: ',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  _formatMetodo(metodoFavorito!),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _leyenda(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  String _formatMetodo(String metodo) {
    switch (metodo) {
      case 'TRANSFERENCIA':
        return 'Transferencia';
      case 'EFECTIVO':
        return 'Efectivo';
      case 'CHEQUE':
        return 'Cheque';
      default:
        return 'Otro';
    }
  }
}
