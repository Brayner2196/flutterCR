import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../providers/cobros_provider.dart';
import '../../models/cobro_model.dart';
import '../../models/periodo_cobro_model.dart';
import '../../widgets/recaudo_card.dart';
import '../../widgets/estado_resumen_grid.dart';
import '../../widgets/mes_selector_bar.dart';
import '../../widgets/cobro_tile.dart';
import '../../../../shared/theme/app_theme.dart';
import 'admin_generar_cobros_screen.dart';
import 'admin_cobro_especial_screen.dart';
import 'admin_cobro_detalle_screen.dart';

/// Pestaña "Cobros" del hub (rediseño unificado).
///
/// Orden de lectura: período → recaudo (tarjeta azul con anillo) → estados
/// (grid 2x2 que filtra) → lista de cobros. Las acciones (cobro especial y
/// generar) viven en una barra inferior fija.
class CobrosTabView extends StatefulWidget {
  const CobrosTabView({super.key});

  @override
  State<CobrosTabView> createState() => CobrosTabViewState();
}

class CobrosTabViewState extends State<CobrosTabView>
    with AutomaticKeepAliveClientMixin {
  PeriodoCobroModel? _periodoSeleccionado;
  String? _estadoFiltro;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CobrosProvider>().cargarPeriodos();
    });
  }

  /// Recarga los cobros del período seleccionado (si hay uno).
  void recargar() {
    if (_periodoSeleccionado != null) {
      context
          .read<CobrosProvider>()
          .cargarCobrosAdmin(periodoId: _periodoSeleccionado!.id);
    }
  }

  /// ¿El período seleccionado está abierto? (lo consulta el hub).
  bool get periodoAbierto => _periodoSeleccionado?.estaAbierto ?? false;

  /// Cierra el período seleccionado. Expuesto para el botón del hub.
  Future<void> cerrarPeriodoActual() async {
    final p = _periodoSeleccionado;
    if (p == null || !p.estaAbierto) {
      _snack('No hay un período abierto para cerrar', AppColors.warning);
      return;
    }
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar período'),
        content: Text(
            'Cerrar el período ${p.nombreMes}? No se podrán generar más cobros para este mes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar período'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    try {
      await context.read<CobrosProvider>().cerrarPeriodo(p.id);
      if (!mounted) return;
      final periodos = context.read<CobrosProvider>().periodos;
      setState(() {
        _periodoSeleccionado = periodos.where((x) => x.id == p.id).firstOrNull;
      });
      _snack('Período cerrado correctamente', AppColors.ok);
      context.read<CobrosProvider>().cargarPeriodos();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), AppColors.danger);
    }
  }

  Future<void> _exonerarCobro(CobroModel cobro) async {
    final notaCtrl = TextEditingController();
    final nota = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exonerar cobro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Propiedad: ${cobro.propiedadIdentificador}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('Monto: ${cobro.montoTotal.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: notaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota de exoneración',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, notaCtrl.text),
            child: const Text('Exonerar'),
          ),
        ],
      ),
    );
    if (nota == null || nota.trim().isEmpty) return;
    try {
      await context.read<CobrosProvider>().exonerar(cobro.id, nota.trim());
      if (!mounted) return;
      _snack('Cobro exonerado', AppColors.purple);
      recargar();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''), AppColors.danger);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ── Acciones de la barra inferior ──────────────────────────────────────

  void _generarCobros() => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                AdminGenerarCobrosScreen(periodo: _periodoSeleccionado)),
      ).then((_) {
        if (mounted) context.read<CobrosProvider>().cargarPeriodos();
        recargar();
      });

  void _cobroEspecial() => Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const AdminCobroEspecialScreen()),
      ).then((r) {
        if (r == true) recargar();
      });

  void _abrirDetalle(CobroModel cobro) => Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => AdminCobroDetalleScreen(cobro: cobro)),
      ).then((cambios) {
        if (cambios == true) recargar();
      });

  // ── Helpers de presentación ────────────────────────────────────────────

  String _mesLabel(PeriodoCobroModel p) =>
      p.nombreMes.split(' ').first.toLowerCase();

  int? _diasCierre(PeriodoCobroModel p) {
    try {
      final limite = DateTime.parse(p.fechaLimitePago);
      final hoy = DateTime.now();
      return DateTime(limite.year, limite.month, limite.day)
          .difference(DateTime(hoy.year, hoy.month, hoy.day))
          .inDays;
    } catch (_) {
      return null;
    }
  }

  Map<String, int> _contar(List<CobroModel> cobros) {
    final counts = <String, int>{};
    for (final c in cobros) {
      counts[c.estado] = (counts[c.estado] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<CobrosProvider>();
    final tienePeriodo = _periodoSeleccionado != null;
    final hayCobros = tienePeriodo && provider.cobros.isNotEmpty;

    // Carga inicial de períodos: aún no hay barra de meses que mostrar.
    final cargaInicial = provider.loading && provider.periodos.isEmpty;
    // Cambio de mes / recarga: mantener barra visible y esqueletizar las
    // secciones que cambian (recaudo, grid de estados y lista).
    final cargandoCobros = provider.loading && tienePeriodo;

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: _barraAcciones(),
      body: cargaInicial
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (provider.periodos.isNotEmpty)
                  MesSelectorBar(
                    periodos: provider.periodos,
                    seleccionado: _periodoSeleccionado,
                    onSeleccionar: (sel) {
                      setState(() {
                        _periodoSeleccionado = sel;
                        _estadoFiltro = null;
                      });
                      context
                          .read<CobrosProvider>()
                          .cargarCobrosAdmin(periodoId: sel.id);
                    },
                  ),
                Expanded(
                  child: cargandoCobros
                      ? _contenidoSkeleton()
                      : hayCobros
                          ? _contenido(provider)
                          : _vacio(provider, tienePeriodo),
                ),
              ],
            ),
    );
  }

  /// Esqueleto de las secciones que cambian al seleccionar otro mes:
  /// tarjeta de recaudo (anillo de %), grid de cobros por estado y lista.
  /// Usa datos ficticios solo para dar forma; Skeletonizer los oculta.
  Widget _contenidoSkeleton() {
    final mesLabel =
        _periodoSeleccionado != null ? _mesLabel(_periodoSeleccionado!) : '';
    const fakeCounts = {
      'VENCIDO': 3,
      'PENDIENTE': 8,
      'PARCIAL': 2,
      'PAGADO': 12,
    };
    final fakeCobros = List.generate(
      6,
      (i) => const CobroModel(
        id: 0,
        propiedadId: 0,
        propiedadIdentificador: 'Apto 000',
        concepto: 'Administración mensual',
        montoBase: 150000,
        montoMora: 0,
        montoTotal: 150000,
        montoPagado: 0,
        montoPendiente: 150000,
        fechaGeneracion: '2024-01-01',
        fechaLimitePago: '2024-01-15',
        estado: 'PENDIENTE',
      ),
    );

    return Skeletonizer(
      enabled: true,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: RecaudoCard(
              totalRecaudado: 1800000,
              totalEsperado: 2500000,
              mesLabel: mesLabel,
              diasCierre: 5,
            ),
          ),
          SliverToBoxAdapter(
            child: EstadoResumenGrid(
              counts: fakeCounts,
              seleccionado: null,
              onSeleccionar: (_) {},
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            sliver: SliverList.builder(
              itemCount: fakeCobros.length,
              itemBuilder: (_, i) => CobroTile(cobro: fakeCobros[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido(CobrosProvider provider) {
    final p = _periodoSeleccionado!;
    final cobros = provider.cobros;
    final counts = _contar(cobros);
    final recaudado = cobros.fold<double>(0, (s, c) => s + c.montoPagado);
    final esperado = cobros.fold<double>(0, (s, c) => s + c.montoTotal);

    final visibles = _estadoFiltro == null
        ? cobros
        : cobros.where((c) => c.estado == _estadoFiltro).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: RecaudoCard(
            totalRecaudado: recaudado,
            totalEsperado: esperado,
            mesLabel: _mesLabel(p),
            diasCierre: _diasCierre(p),
            cerrado: !p.estaAbierto,
          ),
        ),
        SliverToBoxAdapter(
          child: EstadoResumenGrid(
            counts: counts,
            seleccionado: _estadoFiltro,
            onSeleccionar: (v) => setState(() => _estadoFiltro = v),
          ),
        ),
        SliverToBoxAdapter(child: _encabezadoLista(p, cobros.length, visibles.length)),
        if (visibles.isEmpty)
          SliverToBoxAdapter(child: _sinFiltro())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            sliver: SliverList.builder(
              itemCount: visibles.length,
              itemBuilder: (_, i) => CobroTile(
                cobro: visibles[i],
                onExonerar: _exonerarCobro,
                onTap: () => _abrirDetalle(visibles[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _encabezadoLista(PeriodoCobroModel p, int total, int visibles) {
    final cs = Theme.of(context).colorScheme;
    final filtrado = _estadoFiltro != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Text(
            'Cobros de ${_mesLabel(p)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          if (filtrado)
            GestureDetector(
              onTap: () => setState(() => _estadoFiltro = null),
              child: Row(
                children: [
                  Icon(Icons.close, size: 14, color: cs.primary),
                  const SizedBox(width: 2),
                  Text('Ver todos',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary)),
                ],
              ),
            )
          else
            Text(
              '$total propiedades',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _sinFiltro() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.filter_list_off, size: 40, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Sin cobros con ese estado',
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _estadoFiltro = null),
            child: const Text('Quitar filtro'),
          ),
        ],
      ),
    );
  }

  Widget _vacio(CobrosProvider provider, bool tienePeriodo) {
    final cs = Theme.of(context).colorScheme;
    if (!tienePeriodo) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            provider.periodos.isEmpty
                ? 'Aún no hay períodos. Genera el primer cobro desde la barra inferior.'
                : 'Selecciona un período para ver sus cobros.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Sin cobros para este período',
              style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          if (_periodoSeleccionado!.estaAbierto)
            FilledButton.icon(
              onPressed: _generarCobros,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generar cobros'),
            ),
        ],
      ),
    );
  }

  /// Barra inferior fija con las acciones del módulo.
  Widget _barraAcciones() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cobroEspecial,
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('Cobro especial'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _generarCobros,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Generar cobros'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
