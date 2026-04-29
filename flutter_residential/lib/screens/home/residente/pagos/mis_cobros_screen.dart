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
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pendientes'),
                  if (provider.pendientes.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _badge(provider.pendientes.length, Colors.orange),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Vencidos'),
                  if (provider.vencidos.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _badge(provider.vencidos.length, Colors.red),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pagados'),
                  if (provider.pagados.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _badge(provider.pagados.length, Colors.green),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ─── Resumen financiero ─────────────────
                _ResumenCobros(provider: provider),
                // ─── Lista ──────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _Lista(cobros: provider.pendientes),
                      _Lista(cobros: provider.vencidos),
                      _Lista(cobros: provider.pagados),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _badge(int count, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      );
}

/// Header resumen con totales por estado
class _ResumenCobros extends StatelessWidget {
  final CobrosProvider provider;
  const _ResumenCobros({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cobros = provider.cobros;
    if (cobros.isEmpty) return const SizedBox.shrink();

    final totalPendiente =
        provider.pendientes.fold<double>(0, (s, c) => s + c.montoTotal);
    final totalVencido =
        provider.vencidos.fold<double>(0, (s, c) => s + c.montoTotal);
    final totalPagado =
        provider.pagados.fold<double>(0, (s, c) => s + c.montoTotal);
    final totalMora =
        provider.vencidos.fold<double>(0, (s, c) => s + c.montoMora);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _miniKpi('Pendiente', totalPendiente, Colors.orange),
              const SizedBox(width: 12),
              _miniKpi('Vencido', totalVencido, Colors.red),
              const SizedBox(width: 12),
              _miniKpi('Pagado', totalPagado, Colors.green),
            ],
          ),
          if (totalMora > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.trending_up, size: 14, color: Colors.red.shade300),
                const SizedBox(width: 4),
                Text(
                  'Mora acumulada: ${_fmt(totalMora)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniKpi(String label, double monto, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          Text(
            _fmt(monto),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(Icons.receipt_long, color: color, size: 20),
        ),
        title: Text(cobro.concepto,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${cobro.mes}/${cobro.anio} · ${cobro.propiedadIdentificador}',
              style: const TextStyle(fontSize: 12),
            ),
            Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 10, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text('Vence: ${cobro.fechaLimitePago}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                if (cobro.montoMora > 0) ...[
                  const SizedBox(width: 8),
                  Text('Mora: ${_fmt(cobro.montoMora)}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmt(cobro.montoTotal),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                cobro.estado,
                style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DetalleCobroScreen(cobro: cobro)),
        ),
      ),
    );
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
