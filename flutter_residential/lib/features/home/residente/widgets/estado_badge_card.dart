import 'package:flutter/material.dart';

/// Card que muestra el estado general del residente (Al día / En mora / Pendiente)
/// con un indicador visual prominente.
class EstadoBadgeCard extends StatelessWidget {
  final bool alDia;
  final bool enMora;
  final double totalDeuda;
  final int cobrosPendientes;
  final int cobrosVencidos;
  final String Function(double) formatMonto;

  const EstadoBadgeCard({
    super.key,
    required this.alDia,
    required this.enMora,
    required this.totalDeuda,
    required this.cobrosPendientes,
    required this.cobrosVencidos,
    required this.formatMonto,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icono;
    final String titulo;
    final String descripcion;

    if (alDia) {
      color = Colors.green;
      icono = Icons.check_circle_rounded;
      titulo = 'Estás al día';
      descripcion = 'No tienes cobros pendientes';
    } else if (enMora) {
      color = Colors.red;
      icono = Icons.warning_amber_rounded;
      titulo = 'Tienes cobros vencidos';
      descripcion =
          '$cobrosVencidos vencido${cobrosVencidos > 1 ? 's' : ''} · $cobrosPendientes pendiente${cobrosPendientes > 1 ? 's' : ''}';
    } else {
      color = Colors.orange;
      icono = Icons.schedule_rounded;
      titulo = 'Cobros por pagar';
      descripcion =
          '$cobrosPendientes cobro${cobrosPendientes > 1 ? 's' : ''} pendiente${cobrosPendientes > 1 ? 's' : ''}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descripcion,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (!alDia)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMonto(totalDeuda),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'Deuda total',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
