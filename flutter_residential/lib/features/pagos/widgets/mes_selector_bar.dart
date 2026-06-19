import 'package:flutter/material.dart';
import '../models/periodo_cobro_model.dart';
import '../../../shared/theme/app_theme.dart';

/// Barra de períodos estilo "tabBar de meses": píldoras sobre un riel gris,
/// la activa en azul de marca. Reemplaza a `PeriodoChipBar` en el rediseño.
///
/// Orden descendente (mes más reciente primero). Cada píldora muestra un
/// candado abierto/cerrado según el estado del período y el año.
///
/// Si [onCrearPeriodo] no es nulo, se antepone un botón "+" para crear un
/// nuevo período (el padre decide cuándo mostrarlo).
class MesSelectorBar extends StatelessWidget {
  final List<PeriodoCobroModel> periodos;
  final PeriodoCobroModel? seleccionado;
  final ValueChanged<PeriodoCobroModel> onSeleccionar;

  /// Acción para crear un nuevo período. Si es nulo, no se muestra el "+".
  final VoidCallback? onCrearPeriodo;

  const MesSelectorBar({
    super.key,
    required this.periodos,
    required this.seleccionado,
    required this.onSeleccionar,
    this.onCrearPeriodo,
  });

  static const _mesesAbrev = [
    '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  List<PeriodoCobroModel> get _ordenados {
    final lista = [...periodos];
    lista.sort((a, b) {
      final porAnio = b.anio.compareTo(a.anio);
      return porAnio != 0 ? porAnio : b.mes.compareTo(a.mes);
    });
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ordenados = _ordenados;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (onCrearPeriodo != null) _botonCrear(context),
            for (final p in ordenados) _pildora(context, p),
          ],
        ),
      ),
    );
  }

  /// Botón "+" para crear un nuevo período (solo cuando el padre lo habilita).
  Widget _botonCrear(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onCrearPeriodo,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Icon(Icons.add, size: 20, color: cs.primary),
          ),
        ),
      ),
    );
  }

  Widget _pildora(BuildContext context, PeriodoCobroModel p) {
    final cs = Theme.of(context).colorScheme;
    final activo = seleccionado?.id == p.id;
    final colorContenido = activo ? Colors.white : cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: activo ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: () => onSeleccionar(p),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  p.estaAbierto ? Icons.lock_open : Icons.lock,
                  size: 14,
                  color: p.estaAbierto
                      ? (activo ? Colors.white : AppColors.ok)
                      : colorContenido,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_mesesAbrev[p.mes]} ${p.anio}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorContenido,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
