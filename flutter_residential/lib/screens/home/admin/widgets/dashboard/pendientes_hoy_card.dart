import 'package:flutter/material.dart';
import '../../../../../models/dashboard/pendientes_hoy.dart';
import 'dashboard_tokens.dart';

class PendientesHoyCard extends StatelessWidget {
  final PendientesHoy data;
  final VoidCallback? onTapComprobantes;
  final VoidCallback? onTapPqrs;
  final VoidCallback? onTapReservas;

  const PendientesHoyCard({
    super.key,
    required this.data,
    this.onTapComprobantes,
    this.onTapPqrs,
    this.onTapReservas,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final partes = <_Pendiente>[
      if (data.comprobantes > 0)
        _Pendiente('${data.comprobantes} comprobantes', onTapComprobantes),
      if (data.pqrs > 0)
        _Pendiente('${data.pqrs} PQRs', onTapPqrs),
      if (data.reservas > 0)
        _Pendiente('${data.reservas} reservas por aprobar', onTapReservas),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(DashboardTokens.radiusCard),
        border: Border.all(color: cs.outline),
      ),
      padding: DashboardTokens.paddingCard,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: DashboardTokens.bgOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.priority_high,
                color: DashboardTokens.fgOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.total} pendientes hoy',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                if (partes.isEmpty)
                  Text('Sin pendientes',
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (int i = 0; i < partes.length; i++) ...[
                        InkWell(
                          onTap: partes[i].onTap,
                          child: Text(
                            partes[i].label,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                              decoration: partes[i].onTap != null
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          ),
                        ),
                        if (i < partes.length - 1)
                          Text('·',
                              style: TextStyle(
                                  fontSize: 13, color: cs.onSurfaceVariant)),
                      ],
                    ],
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _Pendiente {
  final String label;
  final VoidCallback? onTap;
  _Pendiente(this.label, this.onTap);
}
