import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cobros_provider.dart';
import '../../models/cobro_model.dart';
import '../../models/periodo_cobro_model.dart';
import '../../utils/estado_cobro_ui.dart';
import '../../widgets/resumen_recaudo_header.dart';
import '../../widgets/filtro_chips.dart';
import '../../widgets/cobro_tile.dart';
import '../../../../shared/theme/app_theme.dart';
import 'admin_generar_cobros_screen.dart';

/// Pestaña "Cobros" del hub. Operación diaria: seleccionar período,
/// ver recaudo, filtrar por estado y gestionar cobros del mes.
///
/// Es el cuerpo refactorizado de la antigua `AdminCobrosScreen`, ahora
/// apoyado en los widgets reutilizables (header de recaudo, chips, tile).
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

  Future<void> _confirmarCerrarPeriodo() async {
    final p = _periodoSeleccionado;
    if (p == null) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar período'),
        content: Text(
            '¿Cerrar el período ${p.nombreMes}? No se podrán generar más cobros para este mes.'),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Período cerrado correctamente'),
        backgroundColor: AppColors.ok,
      ));
      context.read<CobrosProvider>().cargarPeriodos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.danger,
      ));
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
            Text('Monto: \$${cobro.montoTotal.toStringAsFixed(0)}',
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cobro exonerado'),
        backgroundColor: AppColors.purple,
      ));
      recargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<CobrosProvider>();
    final periodoAbierto = _periodoSeleccionado?.estaAbierto ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  AdminGenerarCobrosScreen(periodo: _periodoSeleccionado)),
        ).then((_) => context.read<CobrosProvider>().cargarPeriodos()),
        icon: const Icon(Icons.add),
        label: const Text('Generar cobros'),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (provider.periodos.isNotEmpty) _selectorPeriodo(provider),
                if (_periodoSeleccionado != null && provider.cobros.isNotEmpty)
                  ResumenRecaudoHeader(
                    totalRecaudado: provider.cobros
                        .fold<double>(0, (s, c) => s + c.montoPagado),
                    totalEsperado: provider.cobros
                        .fold<double>(0, (s, c) => s + c.montoTotal),
                  ),
                if (_periodoSeleccionado != null && provider.cobros.isNotEmpty)
                  _filtros(provider),
                Expanded(child: _listaCobros(provider, periodoAbierto)),
              ],
            ),
    );
  }

  Widget _selectorPeriodo(CobrosProvider provider) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<PeriodoCobroModel>(
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: cs.surface,
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              hint: Text('Seleccionar período',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              value: _periodoSeleccionado,
              items: provider.periodos
                  .map((p) => DropdownMenuItem(
                      value: p,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: p.estaAbierto
                                  ? AppColors.ok
                                  : cs.onSurfaceVariant.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Text(p.nombreMes,
                                style: TextStyle(color: cs.onSurface)),
                          ),
                          Text(
                            p.estaAbierto ? 'ABIERTO' : 'CERRADO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.estaAbierto
                                  ? AppColors.ok
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )))
                  .toList(),
              onChanged: (p) {
                setState(() {
                  _periodoSeleccionado = p;
                  _estadoFiltro = null;
                });
                if (p != null) {
                  context
                      .read<CobrosProvider>()
                      .cargarCobrosAdmin(periodoId: p.id);
                }
              },
            ),
          ),
          if (_periodoSeleccionado != null && _periodoSeleccionado!.estaAbierto)
            IconButton(
              icon: const Icon(Icons.lock_outline, size: 20),
              tooltip: 'Cerrar período',
              onPressed: _confirmarCerrarPeriodo,
            ),
        ],
      ),
    );
  }

  Widget _filtros(CobrosProvider provider) {
    final cobros = provider.cobros;
    final counts = <String, int>{};
    for (final c in cobros) {
      counts[c.estado] = (counts[c.estado] ?? 0) + 1;
    }
    final items = <FiltroChipData>[
      FiltroChipData(
        valor: null,
        label: 'Todos',
        count: cobros.length,
        color: Theme.of(context).colorScheme.primary,
      ),
      for (final code in EstadoCobroUi.orden)
        if (counts[code] != null)
          FiltroChipData(
            valor: code,
            label: EstadoCobroUi.de(code).label,
            count: counts[code]!,
            color: EstadoCobroUi.de(code).color,
          ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: FiltroChips(
        items: items,
        seleccionado: _estadoFiltro,
        onSeleccionar: (v) => setState(() => _estadoFiltro = v),
      ),
    );
  }

  Widget _listaCobros(CobrosProvider provider, bool periodoAbierto) {
    final cs = Theme.of(context).colorScheme;
    if (_periodoSeleccionado == null) {
      return Center(
        child: Text('Selecciona un período o genera el primer cobro con +',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }
    if (provider.cobros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Sin cobros para este período',
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            if (periodoAbierto)
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AdminGenerarCobrosScreen(
                          periodo: _periodoSeleccionado)),
                ).then((_) => recargar()),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generar cobros'),
              ),
          ],
        ),
      );
    }

    final cobros = _estadoFiltro == null
        ? provider.cobros
        : provider.cobros.where((c) => c.estado == _estadoFiltro).toList();

    if (cobros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      itemCount: cobros.length,
      itemBuilder: (_, i) => CobroTile(
        cobro: cobros[i],
        onExonerar: _exonerarCobro,
      ),
    );
  }
}
