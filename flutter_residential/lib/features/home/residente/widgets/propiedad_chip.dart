import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

/// Píldora que muestra la propiedad en contexto (AppBar, encabezados, etc.).
///
/// Widget presentacional puro: no lee providers, no navega y no decide su
/// propia visibilidad. Quien lo usa define qué texto mostrar y si debe
/// verse el chevron de "desplegable".
class PropiedadChip extends StatelessWidget {
  /// Texto visible en la píldora (normalmente el pathCorto).
  final String etiqueta;

  /// Cambia el icono a parqueadero.
  final bool esParqueadero;

  /// Chevron de "desplegable". False cuando el chip es solo informativo:
  /// mostrarlo sin menú detrás sería prometer una acción que no existe.
  final bool mostrarFlecha;

  /// Sin flecha sobra ancho, así que el texto puede respirar más.
  final double maxAnchoTexto;

  const PropiedadChip({
    super.key,
    required this.etiqueta,
    this.esParqueadero = false,
    this.mostrarFlecha = true,
    this.maxAnchoTexto = 110,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            esParqueadero ? Icons.local_parking : Icons.home_outlined,
            size: 16,
            color: cs.primary,
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxAnchoTexto),
            child: Text(
              etiqueta,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (mostrarFlecha) ...[
            const SizedBox(width: 3),
            Icon(Icons.expand_more_rounded, size: 16, color: cs.primary),
          ],
        ],
      ),
    );
  }
}
