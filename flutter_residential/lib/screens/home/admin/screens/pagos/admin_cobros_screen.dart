import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/cobros_provider.dart';
import '../../../../../models/cobro_model.dart';
import '../../../../../models/periodo_cobro_model.dart';
import 'admin_generar_cobros_screen.dart';

class AdminCobrosScreen extends StatefulWidget {
  const AdminCobrosScreen({super.key});

  @override
  State<AdminCobrosScreen> createState() => _AdminCobrosScreenState();
}

class _AdminCobrosScreenState extends State<AdminCobrosScreen> {
  PeriodoCobroModel? _periodoSeleccionado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CobrosProvider>().cargarPeriodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CobrosProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobros'),
        actions: [
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
                Expanded(child: _listaCobros(provider)),
              ],
            ),
    );
  }

  Widget _selectorPeriodo(CobrosProvider provider) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButton<PeriodoCobroModel>(
          isExpanded: true,
          underline: const SizedBox.shrink(),
          hint: const Text('Seleccionar período'),
          value: _periodoSeleccionado,
          items: provider.periodos
              .map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(
                      '${p.nombreMes} — ${p.estado}',
                      style: TextStyle(
                          color: p.estaAbierto
                              ? Colors.green
                              : null))))
              .toList(),
          onChanged: (p) {
            setState(() => _periodoSeleccionado = p);
            if (p != null) {
              context
                  .read<CobrosProvider>()
                  .cargarCobrosAdmin(periodoId: p.id);
            }
          },
        ),
      );

  Widget _listaCobros(CobrosProvider provider) {
    if (_periodoSeleccionado == null) {
      return const Center(
          child: Text('Selecciona un período para ver los cobros',
              style: TextStyle(color: Colors.grey)));
    }
    if (provider.cobros.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Sin cobros para este período',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            if (_periodoSeleccionado!.estaAbierto)
              FilledButton.icon(
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
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: provider.cobros.length,
      itemBuilder: (_, i) => _CobroAdminTile(cobro: provider.cobros[i]),
    );
  }
}

class _CobroAdminTile extends StatelessWidget {
  final CobroModel cobro;
  const _CobroAdminTile({required this.cobro});

  @override
  Widget build(BuildContext context) {
    final colorEstado = cobro.esPagado
        ? Colors.green
        : cobro.esVencido
            ? Colors.red
            : cobro.esExonerado
                ? Colors.purple
                : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorEstado.withValues(alpha: 0.12),
          child: Icon(Icons.home_work, color: colorEstado, size: 20),
        ),
        title: Text(cobro.propiedadIdentificador,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${cobro.usuarioNombre} · ${cobro.concepto}',
            style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmt(cobro.montoTotal),
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
