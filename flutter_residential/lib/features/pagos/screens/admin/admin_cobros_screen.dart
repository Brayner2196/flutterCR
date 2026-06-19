import 'package:flutter/material.dart';
import 'package:flutter_residential/core/utils/currency_formatter.dart';
import 'package:provider/provider.dart';
import '../../providers/cobros_provider.dart';
import '../../models/cobro_model.dart';
import '../../models/periodo_cobro_model.dart';
import '../../../../shared/theme/app_theme.dart';
import 'admin_cobro_especial_screen.dart';
import 'admin_configurar_cuotas_screen.dart';
import 'admin_configurar_mora_screen.dart';
import 'admin_generar_cobros_screen.dart';

class AdminCobrosScreen extends StatefulWidget {
  const AdminCobrosScreen({super.key});

  @override
  State<AdminCobrosScreen> createState() => _AdminCobrosScreenState();
}

class _AdminCobrosScreenState extends State<AdminCobrosScreen> {
  PeriodoCobroModel? _periodoSeleccionado;
  String? _estadoFiltro; // null = todos

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CobrosProvider>().cargarPeriodos();
    });
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
      // Re-sincronizar con el objeto actualizado en la lista del provider
      final periodos = context.read<CobrosProvider>().periodos;
      setState(() {
        _periodoSeleccionado = periodos.where((x) => x.id == p.id).firstOrNull;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Período cerrado correctamente'),
        backgroundColor: Colors.green,
      ));
      context.read<CobrosProvider>().cargarPeriodos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
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
        backgroundColor: Colors.purple,
      ));
      if (_periodoSeleccionado != null) {
        context.read<CobrosProvider>().cargarCobrosAdmin(
            periodoId: _periodoSeleccionado!.id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CobrosProvider>();
    final periodoAbierto = _periodoSeleccionado?.estaAbierto ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.gavel_outlined),
            tooltip: 'Configurar mora',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminConfigurarMoraScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Configurar cuotas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminConfigurarCuotasScreen()),
            ).then((_) {
              if (mounted) {
                context.read<CobrosProvider>().cargarPeriodos();
              }
            }),
          ),
          if (periodoAbierto)
            IconButton(
              icon: const Icon(Icons.lock_outline),
              tooltip: 'Cerrar período',
              onPressed: _confirmarCerrarPeriodo,
            ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'Cobro especial',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminCobroEspecialScreen()),
            ).then((result) {
              if (result == true && mounted && _periodoSeleccionado != null) {
                context.read<CobrosProvider>().cargarCobrosAdmin(
                    periodoId: _periodoSeleccionado!.id);
              }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Generar cobros',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminGenerarCobrosScreen()),
            ).then((_) => context.read<CobrosProvider>().cargarPeriodos()),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (provider.periodos.isNotEmpty) _selectorPeriodo(provider),
                if (_periodoSeleccionado != null && provider.cobros.isNotEmpty)
                  _resumenYFiltros(provider),
                Expanded(child: _listaCobros(provider)),
              ],
            ),
    );
  }

  Widget _selectorPeriodo(CobrosProvider provider) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        color: p.estaAbierto ? AppColors.ok : cs.onSurfaceVariant.withValues(alpha: 0.4),
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
    );
  }

  Widget _resumenYFiltros(CobrosProvider provider) {
    final cs = Theme.of(context).colorScheme;
    final cobros = provider.cobros;
    final totalEsperado = cobros.fold<double>(0, (s, c) => s + c.montoTotal);
    final totalRecaudado = cobros.fold<double>(0, (s, c) => s + c.montoPagado);
    final pct = totalEsperado > 0 ? totalRecaudado / totalEsperado : 0.0;
    final colorPct = pct >= 0.9
        ? AppColors.ok
        : pct >= 0.6
            ? AppColors.warning
            : AppColors.danger;

    final counts = <String, int>{};
    for (final c in cobros) {
      counts[c.estado] = (counts[c.estado] ?? 0) + 1;
    }

    return Container(
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CurrencyFormatter.fmt(totalRecaudado),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'de ${CurrencyFormatter.fmt(totalEsperado)} esperado',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorPct.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorPct,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: cs.surfaceContainerHighest,
              color: colorPct,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filtroChip('Todos', cobros.length, null, cs.primary),
                if (counts['PENDIENTE'] != null)
                  _filtroChip('Pendiente', counts['PENDIENTE']!, 'PENDIENTE', AppColors.warning),
                if (counts['VENCIDO'] != null)
                  _filtroChip('Vencido', counts['VENCIDO']!, 'VENCIDO', AppColors.danger),
                if (counts['PAGADO'] != null)
                  _filtroChip('Pagado', counts['PAGADO']!, 'PAGADO', AppColors.ok),
                if (counts['PARCIAL'] != null)
                  _filtroChip('Parcial', counts['PARCIAL']!, 'PARCIAL', AppColors.orange),
                if (counts['EXONERADO'] != null)
                  _filtroChip('Exonerado', counts['EXONERADO']!, 'EXONERADO', AppColors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtroChip(String label, int count, String? estado, Color color) {
    final selected = _estadoFiltro == estado;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text('$label  $count'),
        selected: selected,
        onSelected: (_) => setState(() => _estadoFiltro = estado),
        selectedColor: color.withValues(alpha: 0.15),
        backgroundColor: Colors.transparent,
        labelStyle: TextStyle(
          color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        ),
        side: BorderSide(
          color: selected ? color : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _listaCobros(CobrosProvider provider) {
    final cs = Theme.of(context).colorScheme;
    if (_periodoSeleccionado == null) {
      return Center(
        child: Text('Registra un primer cobro presionando el boton superior +',
              style: TextStyle(color: cs.onSurfaceVariant)));
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
            if (_periodoSeleccionado!.estaAbierto)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AdminGenerarCobrosScreen(
                                periodo: _periodoSeleccionado)),
                  ).then((_) => context
                      .read<CobrosProvider>()
                      .cargarCobrosAdmin(
                          periodoId: _periodoSeleccionado!.id)),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generar cobros'),
                ),
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
            Text('Sin cobros con estado "$_estadoFiltro"',
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
      padding: const EdgeInsets.all(12),
      itemCount: cobros.length,
      itemBuilder: (_, i) => _CobroAdminTile(
        cobro: cobros[i],
        onExonerar: _exonerarCobro,
      ),
    );
  }
}

class _CobroAdminTile extends StatelessWidget {
  final CobroModel cobro;
  final void Function(CobroModel) onExonerar;
  const _CobroAdminTile({required this.cobro, required this.onExonerar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colorEstado = cobro.esPagado
        ? AppColors.ok
        : cobro.esVencido
            ? AppColors.danger
            : cobro.esExonerado
                ? AppColors.purple
                : AppColors.yellow;
    final puedeExonerar = cobro.esPendiente || cobro.esVencido;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorEstado.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: colorEstado.withValues(alpha: 0.12),
              child: Icon(Icons.home_work, color: colorEstado, size: 20),
            ),
            title: Text(cobro.propiedadIdentificador,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
            subtitle: Text(
                cobro.concepto,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_fmt(cobro.montoTotal),
                    style: TextStyle(
                      fontSize: 16,
                        fontWeight: FontWeight.bold, color: cs.onSurface)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: colorEstado,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(cobro.estado,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10)),
                ),
              ],
            ),
          ),
          if (puedeExonerar)
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: () => onExonerar(cobro),
                  icon: const Icon(Icons.remove_circle_outline, size: 16),
                  label: const Text('Exonerar',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      ' \$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
