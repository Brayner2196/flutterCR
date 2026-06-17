import 'package:flutter/material.dart';
import '../utils/estado_cobro_ui.dart';

/// Badge reutilizable para el estado de un cobro.
///
/// - [solido] = true: pill de fondo lleno con texto blanco (uso en tiles).
/// - [solido] = false: variante suave con borde (uso en cabeceras/listas).
class CobroEstadoBadge extends StatelessWidget {
  final String estado;
  final bool solido;
  final bool mostrarIcono;

  const CobroEstadoBadge({
    super.key,
    required this.estado,
    this.solido = false,
    this.mostrarIcono = false,
  });

  @override
  Widget build(BuildContext context) {
    final ui = EstadoCobroUi.de(estado);

    if (solido) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: ui.color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          ui.label,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: ui.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ui.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mostrarIcono) ...[
            Icon(ui.icono, size: 12, color: ui.color),
            const SizedBox(width: 5),
          ],
          Text(
            ui.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ui.color,
            ),
          ),
        ],
      ),
    );
  }
}
