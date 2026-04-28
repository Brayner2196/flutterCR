import 'package:flutter/material.dart';
import '../../../../models/pqr_model.dart';
import '../../../../widgets/shared/estado_badge.dart';
import '../../../../screens/home/admin/widgets/dashboard/dashboard_tokens.dart';

class DetallePqrScreen extends StatelessWidget {
  final PqrModel pqr;

  const DetallePqrScreen({super.key, required this.pqr});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de PQR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Badges ──────────────────────────
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EstadoBadge(
                    estado: pqr.estado,
                    label: pqr.estadoLegible,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      pqr.tipoLegible,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Asunto ──────────────────────────
            Text(
              pqr.asunto,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // ─── Descripción ─────────────────────
            Text(
              'Descripción',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(pqr.descripcion, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),

            // ─── Fecha de creación ───────────────
            if (pqr.creadoEn != null) ...[
              _InfoRow(
                icono: Icons.access_time_outlined,
                titulo: 'Creada el',
                valor: pqr.creadoEn!,
              ),
              const SizedBox(height: 12),
            ],

            // ─── Timeline de estados ─────────────
            const Divider(height: 32),
            Text(
              'Seguimiento',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _TimelineEstado(
              label: 'Creada',
              activo: true,
              fecha: pqr.creadoEn,
            ),
            _TimelineEstado(
              label: 'En proceso',
              activo: pqr.esEnProceso || pqr.esResuelto || pqr.esCerrado,
            ),
            _TimelineEstado(
              label: 'Resuelta',
              activo: pqr.esResuelto || pqr.esCerrado,
              fecha: pqr.fechaRespuesta,
            ),
            _TimelineEstado(
              label: 'Cerrada',
              activo: pqr.esCerrado,
              esUltimo: true,
            ),

            // ─── Respuesta del admin ─────────────
            if (pqr.respuestaAdmin != null &&
                pqr.respuestaAdmin!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DashboardTokens.bgGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DashboardTokens.fgGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: DashboardTokens.fgGreen),
                        const SizedBox(width: 6),
                        Text(
                          'Respuesta de la administración',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DashboardTokens.fgGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pqr.respuestaAdmin!,
                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                    ),
                    if (pqr.fechaRespuesta != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        pqr.fechaRespuesta!,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _InfoRow({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icono, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$titulo: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(valor, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _TimelineEstado extends StatelessWidget {
  final String label;
  final bool activo;
  final String? fecha;
  final bool esUltimo;

  const _TimelineEstado({
    required this.label,
    required this.activo,
    this.fecha,
    this.esUltimo = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = activo ? cs.primary : cs.outlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activo ? color : Colors.transparent,
                border: Border.all(color: color, width: 2),
              ),
            ),
            if (!esUltimo)
              Container(
                width: 2,
                height: 28,
                color: color,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                  color: activo ? cs.onSurface : cs.onSurfaceVariant,
                ),
              ),
              if (fecha != null)
                Text(
                  fecha!,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              if (!esUltimo) const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
