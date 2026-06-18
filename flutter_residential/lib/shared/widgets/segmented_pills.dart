import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Control segmentado tipo "píldora" sobre un riel gris. El segmento activo
/// queda con fondo de superficie y sombra suave; el resto en texto atenuado.
///
/// Genérico y reutilizable (ej. Cobros/Cobranza). Cada segmento puede llevar
/// un icono opcional.
class SegmentedPills extends StatelessWidget {
  final List<String> labels;
  final List<IconData>? icons;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SegmentedPills({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.icons,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(child: _segmento(context, i)),
        ],
      ),
    );
  }

  Widget _segmento(BuildContext context, int i) {
    final cs = Theme.of(context).colorScheme;
    final activo = selectedIndex == i;
    return Material(
      color: activo ? cs.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      elevation: activo ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        onTap: () => onChanged(i),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icons != null) ...[
                Icon(
                  icons![i],
                  size: 16,
                  color: activo ? cs.primary : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: activo ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
