import 'package:flutter/material.dart';
import '../models/vehiculo_model.dart';
import 'vehiculo_estado_badge.dart';

/// Tarjeta de vehículo reutilizable.
/// [onAprobar] y [onRechazar] se usan en la vista admin.
/// [onEliminar] se usa en la vista residente.
class VehiculoCard extends StatelessWidget {
  final VehiculoModel vehiculo;
  final VoidCallback? onAprobar;
  final VoidCallback? onRechazar;
  final VoidCallback? onEliminar;

  const VehiculoCard({
    super.key,
    required this.vehiculo,
    this.onAprobar,
    this.onRechazar,
    this.onEliminar,
  });

  static IconData _iconoTipo(TipoVehiculo tipo) {
    switch (tipo) {
      case TipoVehiculo.CARRO:     return Icons.directions_car_outlined;
      case TipoVehiculo.MOTO:      return Icons.two_wheeler_outlined;
      case TipoVehiculo.BICICLETA: return Icons.pedal_bike_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera: ícono + placa + estado ─────────────────────
          Row(
            children: [
              Icon(_iconoTipo(vehiculo.tipo), size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vehiculo.placa.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              VehiculoEstadoBadge(estado: vehiculo.estado),
            ],
          ),

          // ── Tipo + marca/modelo/color ─────────────────────────────
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            children: [
              _Dato(label: 'Tipo', value: vehiculo.tipoLegible),
              if (vehiculo.marca != null && vehiculo.marca!.isNotEmpty)
                _Dato(label: 'Marca', value: vehiculo.marca!),
              if (vehiculo.modelo != null && vehiculo.modelo!.isNotEmpty)
                _Dato(label: 'Modelo', value: vehiculo.modelo!),
              if (vehiculo.color != null && vehiculo.color!.isNotEmpty)
                _Dato(label: 'Color', value: vehiculo.color!),
            ],
          ),

          // ── Parqueadero asignado ──────────────────────────────────
          if (vehiculo.parqueaderoIdentificador != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.local_parking, size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                'Parqueadero ${vehiculo.parqueaderoIdentificador}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ]),
          ],

          // ── Motivo rechazo ────────────────────────────────────────
          if (vehiculo.esRechazado && vehiculo.motivoRechazo != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 13, color: cs.error),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    vehiculo.motivoRechazo!,
                    style: TextStyle(fontSize: 12, color: cs.error),
                  ),
                ),
              ],
            ),
          ],

          // ── Botones admin ─────────────────────────────────────────
          if (vehiculo.esPendiente &&
              (onAprobar != null || onRechazar != null)) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onRechazar != null)
                  OutlinedButton(
                    onPressed: onRechazar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                      minimumSize: const Size(88, 40),
                    ),
                    child: const Text('Rechazar'),
                  ),
                if (onAprobar != null) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onAprobar,
                    style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
                    child: const Text('Aprobar'),
                  ),
                ],
              ],
            ),
          ],

          // ── Botón eliminar (residente) ────────────────────────────
          if (onEliminar != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEliminar,
                icon: Icon(Icons.delete_outline, size: 16, color: cs.error),
                label: Text('Eliminar', style: TextStyle(color: cs.error)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip de dato compacto (label: valor).
class _Dato extends StatelessWidget {
  final String label;
  final String value;

  const _Dato({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 12, color: cs.onSurface),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
