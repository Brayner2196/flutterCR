import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/cobros_provider.dart';
import '../../../../models/cobro_model.dart';
import '../../../../models/estado_cuenta_model.dart';
import 'detalle_cobro_screen.dart';
import 'mis_cobros_screen.dart';

class EstadoCuentaScreen extends StatefulWidget {
  const EstadoCuentaScreen({super.key});

  @override
  State<EstadoCuentaScreen> createState() => _EstadoCuentaScreenState();
}

class _EstadoCuentaScreenState extends State<EstadoCuentaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<CobrosProvider>().cargarEstadoCuenta());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CobrosProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Estado de Cuenta')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _error(provider.error!)
              : _body(provider.estadoCuenta),
    );
  }

  Widget _error(String msg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center),
            TextButton(
              onPressed: () =>
                  context.read<CobrosProvider>().cargarEstadoCuenta(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );

  Widget _body(EstadoCuentaModel? ec) {
    if (ec == null) return const SizedBox.shrink();
    return RefreshIndicator(
      onRefresh: () => context.read<CobrosProvider>().cargarEstadoCuenta(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tarjetaResumen(ec),
          const SizedBox(height: 16),
          if (ec.cobrosActivos.isNotEmpty) ...[            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cobros activos',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MisCobrosScreen())),
                  child: const Text('Ver historial'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...ec.cobrosActivos.map((c) => _CobroCard(cobro: c)),
          ] else
            _tarjetaAlDia(),
        ],
      ),
    );
  }

  Widget _tarjetaResumen(EstadoCuentaModel ec) {
    final deuda = ec.totalDeuda;
    final color = deuda > 0 ? Colors.red : Colors.green;
    return Card(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(
                  deuda > 0
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
                  color: color),
              const SizedBox(width: 8),
              Text(
                  deuda > 0
                      ? 'Tienes deuda pendiente'
                      : 'Estás al día',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color)),
            ]),
            const SizedBox(height: 16),
            Text(_fmt(deuda),
                style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: color)),
            if (ec.totalVencido > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    'Incluye ${_fmt(ec.totalVencido)} en mora',
                    style: TextStyle(
                        color: Colors.red.shade700, fontSize: 12)),
              ),
            const SizedBox(height: 8),
            Text(
                '${ec.cobrosPendientes} pendientes · ${ec.cobrosVencidos} vencidos',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaAlDia() => Card(
        color: Colors.green.shade50,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 52),
              SizedBox(height: 12),
              Text('¡Estás al día!',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 4),
              Text('No tienes cobros pendientes',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );

  String _fmt(double v) => '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

class _CobroCard extends StatelessWidget {
  final CobroModel cobro;
  const _CobroCard({required this.cobro});

  @override
  Widget build(BuildContext context) {
    final color = cobro.esVencido ? Colors.red : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3))),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.receipt_long, color: color, size: 22),
        ),
        title: Text(cobro.propiedadIdentificador,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Vence: ${cobro.fechaLimitePago}',
            style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmt(cobro.montoTotal),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4)),
              child: Text(cobro.estado,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10)),
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

  String _fmt(double v) => '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
