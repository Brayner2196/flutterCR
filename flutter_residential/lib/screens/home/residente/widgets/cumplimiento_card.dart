import 'package:flutter/material.dart';

/// Card que muestra el porcentaje de cumplimiento del residente
/// con una barra de progreso circular o lineal.
class CumplimientoCard extends StatelessWidget {
  final double porcentaje;
  final int pagados;
  final int total;
  final double totalPagado;
  final String Function(double) formatMonto;

  const CumplimientoCard({
    super.key,
    required this.porcentaje,
    required this.pagados,
    required this.total,
    required this.totalPagado,
    required this.formatMonto,
  });

  @override
  Widget build(BuildContext context) {
    final color = porcentaje >= 80
        ? Colors.green
        : porcentaje >= 50
            ? Colors.orange
            : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Indicador circular
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: porcentaje / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Text(
                    '${porcentaje.toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cumplimiento de pagos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pagados de $total cobros pagados',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total pagado: ${formatMonto(totalPagado)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
