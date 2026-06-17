import 'package:flutter/material.dart';

/// Dato para un chip de filtro (estado de cobro, fase de cartera, etc.).
class FiltroChipData {
  /// Valor que representa el chip. `null` = "Todos".
  final String? valor;
  final String label;
  final int count;
  final Color color;

  const FiltroChipData({
    required this.valor,
    required this.label,
    required this.count,
    required this.color,
  });
}

/// Fila horizontal de chips de filtro reutilizable.
///
/// Sustituye los `ChoiceChip` duplicados en las pantallas de cobros y
/// cobranza. Es agnóstico al dominio: se le pasan los [items] ya calculados.
class FiltroChips extends StatelessWidget {
  final List<FiltroChipData> items;
  final String? seleccionado;
  final ValueChanged<String?> onSeleccionar;

  const FiltroChips({
    super.key,
    required this.items,
    required this.seleccionado,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text('${item.label}  ${item.count}'),
                selected: seleccionado == item.valor,
                onSelected: (_) => onSeleccionar(item.valor),
                selectedColor: item.color.withValues(alpha: 0.15),
                backgroundColor: Colors.transparent,
                labelStyle: TextStyle(
                  color: seleccionado == item.valor
                      ? item.color
                      : cs.onSurfaceVariant,
                  fontWeight: seleccionado == item.valor
                      ? FontWeight.w600
                      : FontWeight.normal,
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: seleccionado == item.valor
                      ? item.color
                      : cs.outlineVariant,
                  width: seleccionado == item.valor ? 1.5 : 1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
