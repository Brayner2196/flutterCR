import 'package:flutter/material.dart';
import '../../../../../models/dashboard/estado_unidades.dart';
import 'dashboard_tokens.dart';

class EstadoUnidadesCard extends StatelessWidget {
  final EstadoUnidades data;

  const EstadoUnidadesCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(DashboardTokens.radiusCard),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estado de unidades',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                '${data.total} totales',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BarraSegmentada(data: data),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Leyenda(color: DashboardTokens.fgGreen, label: 'Al día', valor: data.alDia),
              _Leyenda(color: DashboardTokens.fgYellow, label: 'Por vencer', valor: data.porVencer),
              _Leyenda(color: DashboardTokens.fgRed, label: 'En mora', valor: data.enMora),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarraSegmentada extends StatelessWidget {
  final EstadoUnidades data;
  const _BarraSegmentada({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.total <= 0 ? 1 : data.total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Expanded(
              flex: data.alDia,
              child: Container(color: DashboardTokens.fgGreen),
            ),
            Expanded(
              flex: data.porVencer,
              child: Container(color: DashboardTokens.fgYellow),
            ),
            Expanded(
              flex: data.enMora,
              child: Container(color: DashboardTokens.fgRed),
            ),
            if (data.alDia + data.porVencer + data.enMora == 0)
              Expanded(flex: total, child: Container(color: Colors.black12)),
          ],
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String label;
  final int valor;
  const _Leyenda({required this.color, required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label $valor',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
