import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/cobros_provider.dart';
import '../../../../models/cobro_model.dart';
import 'detalle_cobro_screen.dart';

class MisCobrosScreen extends StatefulWidget {
  const MisCobrosScreen({super.key});

  @override
  State<MisCobrosScreen> createState() => _MisCobrosScreenState();
}

class _MisCobrosScreenState extends State<MisCobrosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CobrosProvider>().cargarMisCobros();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CobrosProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cobros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CobrosProvider>().cargarMisCobros(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Vencidos'),
            Tab(text: 'Pagados'),
          ],
        ),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _Lista(cobros: provider.pendientes),
                _Lista(cobros: provider.vencidos),
                _Lista(cobros: provider.pagados),
              ],
            ),
    );
  }
}

class _Lista extends StatelessWidget {
  final List<CobroModel> cobros;
  const _Lista({required this.cobros});

  @override
  Widget build(BuildContext context) {
    if (cobros.isEmpty) {
      return const Center(
          child: Text('Sin cobros en esta categoría',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cobros.length,
      itemBuilder: (_, i) => _CobroTile(cobro: cobros[i]),
    );
  }
}

class _CobroTile extends StatelessWidget {
  final CobroModel cobro;
  const _CobroTile({required this.cobro});

  @override
  Widget build(BuildContext context) {
    final color = cobro.esPagado
        ? Colors.green
        : cobro.esVencido
            ? Colors.red
            : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.receipt_long, color: color, size: 20),
        ),
        title: Text(cobro.propiedadIdentificador,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${cobro.mes}/${cobro.anio} · Vence: ${cobro.fechaLimitePago}',
            style: const TextStyle(fontSize: 12)),
        trailing: Text(_fmt(cobro.montoTotal),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color)),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DetalleCobroScreen(cobro: cobro)),
        ),
      ),
    );
  }

  String _fmt(double v) => '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
