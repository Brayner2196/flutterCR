import 'package:flutter/material.dart';
import '../models/periodo_cobro_model.dart';
import '../../../shared/theme/app_theme.dart';

/// Barra de períodos estilo "tabBar de meses": píldoras sobre un riel gris,
/// la activa en azul de marca. Reemplaza a `PeriodoChipBar` en el rediseño.
///
/// Orden descendente (mes más reciente primero). Si hay varios años, agrega
/// el año cuando cambia para evitar ambigüedad.
class MesSelectorBar extends StatelessWidget {
  final List<PeriodoCobroModel> periodos;
  final PeriodoCobroModel? seleccionado;
  final ValueChanged<PeriodoCobroModel> onSeleccionar;

  const MesSelectorBar({
    super.key,
    required this.periodos,
    required this.seleccionado,
    required this.onSeleccionar,
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
    final variosAnios = periodos.map((p) => p.anio).toSet().length > 1;

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
            for (final p in ordenados) _pildora(context, p, variosAnios),
          ],
        ),
      ),
    );
  }

  Widget _pildora(
      BuildContext context, PeriodoCobroModel p, bool conAnio) {
    final cs = Theme.of(context).colorScheme;
    final activo = seleccionado?.id == p.id;
    final texto = conAnio
        ? '${_mesesAbrev[p.mes]} ${p.anio}'
        : _mesesAbrev[p.mes];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: activo ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: () => onSeleccionar(p),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.estaAbierto
                        ? (activo ? Colors.white : AppColors.ok)
                        : (activo
                            ? Colors.white.withValues(alpha: 0.5)
                            : cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  ),
                ),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: activo ? Colors.white : cs.onSurfaceVariant,
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
