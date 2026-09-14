import 'package:flutter/material.dart';
import '../../../core/utils/currency_formatter.dart';
import '../utils/agrupador_cobranza.dart';

/// Encabezado de un mes dentro de la lista de cartera: nombre del mes, cuánto
/// se debe en él y un atajo para marcar (o desmarcar) sus cobros de una vez.
class GrupoMesHeader extends StatelessWidget {
  final GrupoMesCobranza grupo;

  /// True cuando todos los cobros visibles del mes ya están seleccionados.
  final bool todosSeleccionados;

  final VoidCallback onAlternarTodos;

  /// False oculta el atajo de selección (usuario sin permiso de notificar).
  final bool mostrarSeleccion;

  const GrupoMesHeader({
    super.key,
    required this.grupo,
    required this.todosSeleccionados,
    required this.onAlternarTodos,
    this.mostrarSeleccion = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grupo.nombre,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  '${grupo.cantidad} ${grupo.cantidad == 1 ? 'cobro' : 'cobros'} · '
                  '${CurrencyFormatter.cop(grupo.totalPendiente)}',
                  style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (mostrarSeleccion)
            TextButton.icon(
              onPressed: onAlternarTodos,
              icon: Icon(
                todosSeleccionados
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
                size: 16,
              ),
              label: Text(
                todosSeleccionados ? 'Quitar' : 'Seleccionar',
                style: const TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}
