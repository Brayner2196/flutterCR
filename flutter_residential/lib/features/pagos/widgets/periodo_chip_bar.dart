import 'package:flutter/material.dart';
import '../models/periodo_cobro_model.dart';

/// Barra horizontal de períodos de cobro en forma de chips.
///
/// Replica el estilo de los chips de categoría del marketplace (pill con
/// relleno sólido `primary` cuando está activo) y añade el candado de estado:
/// abierto (período ABIERTO) o cerrado (CERRADO).
///
/// - Orden descendente: el más reciente queda a la izquierda.
/// - Muestra [pagina] chips y revela los siguientes al deslizar (paginado
///   visual sobre la lista ya cargada).
class PeriodoChipBar extends StatefulWidget {
  final List<PeriodoCobroModel> periodos;
  final PeriodoCobroModel? seleccionado;
  final ValueChanged<PeriodoCobroModel> onSeleccionar;

  /// Cantidad inicial de chips visibles y tamaño de cada "página".
  final int pagina;

  const PeriodoChipBar({
    super.key,
    required this.periodos,
    required this.seleccionado,
    required this.onSeleccionar,
    this.pagina = 6,
  });

  @override
  State<PeriodoChipBar> createState() => _PeriodoChipBarState();
}

class _PeriodoChipBarState extends State<PeriodoChipBar> {
  static const _mesesAbrev = [
    '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  final ScrollController _scroll = ScrollController();
  late int _visibles;

  @override
  void initState() {
    super.initState();
    _visibles = widget.pagina;
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 64) {
      _revelarMas();
    }
  }

  void _revelarMas() {
    if (_visibles < widget.periodos.length) {
      setState(() => _visibles =
          (_visibles + widget.pagina).clamp(0, widget.periodos.length));
    }
  }

  /// Períodos ordenados del más reciente al más antiguo.
  List<PeriodoCobroModel> get _ordenados {
    final lista = [...widget.periodos];
    lista.sort((a, b) {
      final porAnio = b.anio.compareTo(a.anio);
      return porAnio != 0 ? porAnio : b.mes.compareTo(a.mes);
    });
    return lista;
  }

  String _label(PeriodoCobroModel p) => '${_mesesAbrev[p.mes]} ${p.anio}';

  @override
  Widget build(BuildContext context) {
    final ordenados = _ordenados;
    final total = ordenados.length;
    final cuenta = _visibles.clamp(0, total);
    final hayMas = cuenta < total;

    return SizedBox(
      height: 44,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: cuenta + (hayMas ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= cuenta) return _chipMas(total - cuenta);
          return _chip(ordenados[i]);
        },
      ),
    );
  }

  Widget _chip(PeriodoCobroModel p) {
    final cs = Theme.of(context).colorScheme;
    final activo = widget.seleccionado?.id == p.id;
    final colorContenido = activo ? cs.onPrimaryContainer : cs.onSurface;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: () => widget.onSeleccionar(p),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: activo ? cs.primary : cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activo ? cs.primary : cs.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                p.estaAbierto ? Icons.lock_open : Icons.lock,
                size: 13,
                color: colorContenido,
              ),
              const SizedBox(width: 5),
              Text(
                _label(p),
                style: TextStyle(
                  color: colorContenido,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chip final para revelar manualmente los siguientes períodos.
  Widget _chipMas(int restantes) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: _revelarMas,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.more_horiz, size: 15, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '+$restantes',
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
