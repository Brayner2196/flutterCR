import 'package:flutter/material.dart';

/// Widget reutilizable para estados vacíos con icono, mensaje y CTA opcional.
class EmptyStateWidget extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final String? textoBoton;
  final VoidCallback? onBoton;

  const EmptyStateWidget({
    super.key,
    required this.icono,
    required this.mensaje,
    this.textoBoton,
    this.onBoton,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (textoBoton != null && onBoton != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onBoton,
              icon: const Icon(Icons.add, size: 18),
              label: Text(textoBoton!),
            ),
          ],
        ],
      ),
    );
  }
}
