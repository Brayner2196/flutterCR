import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/pago_model.dart';
import '../../../../providers/pagos_provider.dart';

class MisPagosScreen extends StatefulWidget {
  const MisPagosScreen({super.key});

  @override
  State<MisPagosScreen> createState() => _MisPagosScreenState();
}

class _MisPagosScreenState extends State<MisPagosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PagosProvider>().cargarMisPagos();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PagosProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pagos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PagosProvider>().cargarMisPagos(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Verificados'),
            Tab(text: 'Rechazados'),
          ],
        ),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _error(provider.error!)
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _ListaPagos(pagos: provider.pendientes),
                    _ListaPagos(pagos: provider.verificados),
                    _ListaPagos(pagos: provider.rechazados),
                  ],
                ),
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
                  context.read<PagosProvider>().cargarMisPagos(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
}

class _ListaPagos extends StatelessWidget {
  final List<PagoModel> pagos;
  const _ListaPagos({required this.pagos});

  @override
  Widget build(BuildContext context) {
    if (pagos.isEmpty) {
      return const Center(
        child: Text('Sin pagos en esta categoría',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pagos.length,
      itemBuilder: (_, i) => _PagoTile(pago: pagos[i]),
    );
  }
}

class _PagoTile extends StatelessWidget {
  final PagoModel pago;
  const _PagoTile({required this.pago});

  Color get _color {
    if (pago.esVerificado) return Colors.green;
    if (pago.esRechazado) return Colors.red;
    return Colors.orange;
  }

  IconData get _icono {
    if (pago.esVerificado) return Icons.check_circle_outline;
    if (pago.esRechazado) return Icons.cancel_outlined;
    return Icons.hourglass_top_outlined;
  }

  String get _etiquetaEstado {
    if (pago.esVerificado) return 'VERIFICADO';
    if (pago.esRechazado) return 'RECHAZADO';
    return 'PENDIENTE';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_icono, color: _color, size: 20),
                    const SizedBox(width: 8),
                    Text(_fmt(pago.montoPagado),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _color)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_etiquetaEstado,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _color)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _fila('Fecha', pago.fechaPago),
            _fila('Método', pago.metodoPago),
            if (pago.referencia != null) _fila('Referencia', pago.referencia!),
            if (pago.fechaVerificacion != null)
              _fila('Verificado el', pago.fechaVerificacion!),
            if (pago.notas != null && pago.notas!.isNotEmpty)
              _fila('Notas', pago.notas!),
            if (pago.esRechazado && pago.motivoRechazo != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Motivo: ${pago.motivoRechazo}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fila(String label, String valor) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text('$label: ',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Expanded(
              child: Text(valor, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
