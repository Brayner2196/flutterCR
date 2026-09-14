import 'package:flutter/material.dart';
import '../models/periodo_cobro_model.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/mes_pildora.dart';

/// Barra de períodos estilo "tabBar de meses": píldoras sobre un riel gris,
/// la activa en azul de marca.
///
/// Orden descendente (mes más reciente primero). Cada píldora muestra un
/// candado abierto/cerrado según el estado del período y el año.
///
/// Si [onCrearPeriodo] no es nulo, se antepone un botón "+" para crear un
/// nuevo período (el padre decide cuándo mostrarlo).
///
/// El riel y la píldora viven en `shared/widgets/mes_pildora.dart`: la barra de
/// meses de Cobranza usa las mismas piezas, así que el estilo no se bifurca.
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
    return RielPildoras(
      children: [
        if (onCrearPeriodo != null) _botonCrear(context),
        for (final p in _ordenados)
          MesPildora(
            label: '${_mesesAbrev[p.mes]} ${p.anio}',
            activo: seleccionado?.id == p.id,
            icono: p.estaAbierto ? Icons.lock_open : Icons.lock,
            colorIcono: p.estaAbierto ? AppColors.ok : null,
            onTap: () => onSeleccionar(p),
          ),
      ],
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
}
