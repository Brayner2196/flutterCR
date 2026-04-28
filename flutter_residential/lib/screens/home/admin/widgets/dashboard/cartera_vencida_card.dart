import 'package:flutter/material.dart';
import '../../../../../models/dashboard/cartera_vencida.dart';
import 'dashboard_tokens.dart';

class CarteraVencidaCard extends StatelessWidget {
  final CarteraVencida data;

  const CarteraVencidaCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final positivo = data.variacionMonto >= 0;
    return Container(
      decoration: BoxDecoration(
        color: DashboardTokens.bgOrange,
        borderRadius: BorderRadius.circular(DashboardTokens.radiusCard),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cartera vencida',
              style: TextStyle(fontSize: 13, color: DashboardTokens.fgOrange)),
          const SizedBox(height: 8),
          Text(
            formatoMillones(data.monto),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: DashboardTokens.fgOrange,
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              Row(
                children: [
                  Icon(
                    positivo ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: DashboardTokens.fgOrange,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${positivo ? '+' : '−'}${formatoMillones(data.variacionMonto.abs())}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: DashboardTokens.fgOrange,
                    ),
                  ),
                  
                ],
              ),
                  Text(
                    '${data.unidadesEnMora} unidades en mora',
                    style: const TextStyle(
                        fontSize: 14, color: DashboardTokens.fgOrange),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
