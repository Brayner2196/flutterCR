import 'package:flutter/material.dart';

/// Barra inferior contextual de una selección múltiple: cuántos elementos hay
/// marcados, cómo limpiarlos y la acción principal sobre ellos.
///
/// Genérica a propósito (no sabe de cobranza): cualquier lista que gane
/// selección múltiple —pagos por verificar, PQR, residentes— puede usarla sin
/// volver a inventar la barra.
class SeleccionBar extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final VoidCallback onLimpiar;
  final VoidCallback? onAccion;
  final String textoAccion;
  final IconData iconoAccion;

  /// Deshabilita la acción y muestra un indicador mientras se procesa.
  final bool ocupado;

  const SeleccionBar({
    super.key,
    required this.titulo,
    required this.onLimpiar,
    required this.onAccion,
    required this.textoAccion,
    this.iconoAccion = Icons.send,
    this.subtitulo,
    this.ocupado = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: ocupado ? null : onLimpiar,
                icon: const Icon(Icons.close),
                tooltip: 'Limpiar selección',
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    if (subtitulo != null)
                      Text(
                        subtitulo!,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onPrimaryContainer.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: ocupado ? null : onAccion,
                icon: ocupado
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(iconoAccion, size: 18),
                label: Text(textoAccion),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
