import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../models/parqueadero_model.dart';

/// Tarjeta de parqueadero.
/// Soporta acción opcional de asignar/desasignar propiedad (admin)
/// y de cambiar vehículo (residente).
class ParqueaderoCard extends StatelessWidget {
  final ParqueaderoModel parqueadero;
  final VoidCallback? onAsignarPropiedad;
  final VoidCallback? onEliminar;
  final VoidCallback? onCambiarVehiculo;

  const ParqueaderoCard({
    super.key,
    required this.parqueadero,
    this.onAsignarPropiedad,
    this.onEliminar,
    this.onCambiarVehiculo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = parqueadero;

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
          // ── Cabecera: identificador + estado ─────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: p.tieneVehiculo
                      ? AppColors.bgGreen
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_parking,
                  size: 18,
                  color: p.tieneVehiculo ? AppColors.ok : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.identificador,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (p.modeloPropiedad != null) ...[
                          const SizedBox(width: 6),
                          _ModeloBadge(modelo: p.modeloPropiedad!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.tieneAsignacion
                          ? ((p.propiedadPath ?? p.propiedadIdentificador) != null
                              ? 'Propiedad: ${p.propiedadPath ?? p.propiedadIdentificador}'
                              : 'Propiedad independiente')
                          : 'Sin asignar',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge de estado: ocupado (con vehículo) / asignado / sin asignar
              _EstadoBadge(
                tieneVehiculo: p.tieneVehiculo,
                tieneAsignacion: p.tieneAsignacion,
              ),
            ],
          ),

          // ── Vehículo asignado ─────────────────────────────────────
          if (p.tieneVehiculo) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.directions_car_outlined,
                  size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${p.vehiculoPlaca}${p.vehiculoTipo != null ? ' · ${p.vehiculoTipo}' : ''}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ]),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Sin vehículo asignado',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],

          // ── Acciones admin ────────────────────────────────────────
          if (onAsignarPropiedad != null || onEliminar != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEliminar != null)
                  TextButton.icon(
                    onPressed: onEliminar,
                    icon: Icon(Icons.delete_outline, size: 15, color: cs.error),
                    label: Text('Eliminar',
                        style: TextStyle(fontSize: 12, color: cs.error)),
                  ),
                if (onAsignarPropiedad != null) ...[
                  const SizedBox(width: 4),
                  OutlinedButton(
                    onPressed: onAsignarPropiedad,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 36),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(p.tienePropiedad ? 'Cambiar propiedad' : 'Asignar propiedad'),
                  ),
                ],
              ],
            ),
          ],

          // ── Acción residente: cambiar vehículo ────────────────────
          if (onCambiarVehiculo != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onCambiarVehiculo,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: Text(p.tieneVehiculo ? 'Cambiar vehículo' : 'Asignar vehículo'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final bool tieneVehiculo;
  final bool tieneAsignacion;

  const _EstadoBadge({
    required this.tieneVehiculo,
    required this.tieneAsignacion,
  });

  @override
  Widget build(BuildContext context) {
    // Prioridad: con vehículo → Ocupado; asignado sin vehículo → Asignado; nada → Sin asignar
    final String texto;
    final Color bg;
    final Color fg;
    if (tieneVehiculo) {
      texto = 'Ocupado';
      bg = AppColors.bgGreen;
      fg = AppColors.ok;
    } else if (tieneAsignacion) {
      texto = 'Asignado';
      bg = Colors.indigo.withValues(alpha: 0.12);
      fg = Colors.indigo;
    } else {
      texto = 'Sin asignar';
      bg = AppColors.neutralSoft;
      fg = AppColors.textLoLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _ModeloBadge extends StatelessWidget {
  final ModeloParqueaderoPrivado modelo;

  const _ModeloBadge({required this.modelo});

  @override
  Widget build(BuildContext context) {
    final esIndependiente = modelo == ModeloParqueaderoPrivado.INDEPENDIENTE;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (esIndependiente ? Colors.teal : Colors.indigo)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: (esIndependiente ? Colors.teal : Colors.indigo)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        esIndependiente ? 'Independiente' : 'Accesorio',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: esIndependiente ? Colors.teal : Colors.indigo,
        ),
      ),
    );
  }
}
