import 'package:flutter/material.dart';
import '../../../../../models/dashboard/pagos_por_verificar.dart';
import 'dashboard_tokens.dart';

class PagosPorVerificarCard extends StatelessWidget {
  final PagosPorVerificar data;
  final VoidCallback? onTap;

  const PagosPorVerificarCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DashboardTokens.radiusCard),
      child: Container(
        decoration: BoxDecoration(
          color: DashboardTokens.bgPurple,
          borderRadius: BorderRadius.circular(DashboardTokens.radiusCard),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pagos por verificar',
                style: TextStyle(fontSize: 13, color: DashboardTokens.fgPurple)),
            const SizedBox(height: 8),
            Text(
              '${data.cantidad}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: DashboardTokens.fgPurple,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.cantidad == 1 ? 'Comprobante nuevo' : 'Comprobantes nuevos',
              style: const TextStyle(fontSize: 12, color: DashboardTokens.fgPurple),
            ),
          ],
        ),
      ),
    );
  }
}
