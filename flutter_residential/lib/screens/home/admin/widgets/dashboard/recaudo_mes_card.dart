import 'package:flutter/material.dart';
import '../../../../../models/dashboard/recaudo_mes.dart';
import 'dashboard_tokens.dart';

class RecaudoMesCard extends StatelessWidget {
  final RecaudoMes data;

  const RecaudoMesCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardTokens.bgGreen,
        borderRadius: BorderRadius.circular(DashboardTokens.radiusCard),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recaudo del mes',
              style: TextStyle(fontSize: 13, color: DashboardTokens.fgGreen)),
          const SizedBox(height: 8),
          Text(
            '${data.porcentaje}%',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: DashboardTokens.fgGreen,
            ),
          ),
          const SizedBox(height: 6),
          _BadgeVariacion(puntos: data.puntosVariacion),
          const SizedBox(height: 8),
          Text(
            '${formatoMillones(data.recaudado)} de ${formatoMillones(data.esperado)}',
            style: const TextStyle(fontSize: 12, color: DashboardTokens.fgGreen),
          ),
          const SizedBox(height: 10),
          _BarritasProgreso(porcentaje: data.porcentaje),
        ],
      ),
    );
  }
}

class _BadgeVariacion extends StatelessWidget {
  final int puntos;
  const _BadgeVariacion({required this.puntos});

  @override
  Widget build(BuildContext context) {
    final positivo = puntos >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positivo ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: positivo ? DashboardTokens.fgGreen : DashboardTokens.fgRed,
          ),
          const SizedBox(width: 2),
          Text(
            '${positivo ? '+' : ''}$puntos pts',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: positivo ? DashboardTokens.fgGreen : DashboardTokens.fgRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarritasProgreso extends StatelessWidget {
  final int porcentaje;
  const _BarritasProgreso({required this.porcentaje});

  @override
  Widget build(BuildContext context) {
    final activos = (porcentaje / 100 * 8).round().clamp(0, 8);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(8, (i) {
        final h = 4.0 + i * 2.0;
        final activa = i < activos;
        return Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Container(
            width: 6,
            height: h,
            decoration: BoxDecoration(
              color: activa
                  ? DashboardTokens.fgGreen
                  : DashboardTokens.fgGreen.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
