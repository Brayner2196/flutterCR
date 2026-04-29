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
                  const Text('Verificados'),
                  if (provider.verificados.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _badge(provider.verificados.length, Colors.green),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Rechazados'),
                  if (provider.rechazados.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _badge(provider.rechazados.length, Colors.red),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _error(provider.error!)
              : Column(
                  children: [
                    // ─── Header de resumen ────────────────
                    _ResumenHeader(provider: provider),
                    // ─── Lista de pagos ──────────────────
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _ListaPagos(pagos: provider.pendientes),
                          _ListaPagos(pagos: provider.verificados),
                          _ListaPagos(pagos: provider.rechazados),
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

/// Header con resumen de pagos: total pagado, distribución por método
class _ResumenHeader extends StatelessWidget {
  final PagosProvider provider;
  const _ResumenHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final pagos = provider.pagos;
    if (pagos.isEmpty) return const SizedBox.shrink();

    final totalPagado = pagos
        .where((p) => p.esVerificado)
        .fold<double>(0, (s, p) => s + p.montoPagado);

    // Distribución por método
    final metodos = <String, int>{};
    for (final p in pagos) {
      metodos[p.metodoPago] = (metodos[p.metodoPago] ?? 0) + 1;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Total pagado verificado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total verificado',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Text(
                  _fmt(totalPagado),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          // Métodos
          ...metodos.entries.take(3).map((e) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  children: [
                    Icon(_iconoMetodo(e.key),
                        size: 18, color: Colors.grey.shade600),
                    const SizedBox(height: 2),
                    Text('${e.value}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(_labelMetodo(e.key),
                        style: TextStyle(
                            fontSize: 9, color: Colors.grey.shade500)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  IconData _iconoMetodo(String metodo) {
    switch (metodo) {
      case 'TRANSFERENCIA':
        return Icons.swap_horiz;
      case 'EFECTIVO':
        return Icons.payments_outlined;
      case 'CHEQUE':
        return Icons.description_outlined;
      default:
        return Icons.credit_card;
    }
  }

  String _labelMetodo(String metodo) {
    switch (metodo) {
      case 'TRANSFERENCIA':
        return 'Transf.';
      case 'EFECTIVO':
        return 'Efectivo';
      case 'CHEQUE':
        return 'Cheque';
      default:
        return 'Otro';
    }
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
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
            _fila('Método', _formatMetodo(pago.metodoPago)),
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

  String _formatMetodo(String metodo) {
    switch (metodo) {
      case 'TRANSFERENCIA':
        return 'Transferencia';
      case 'EFECTIVO':
        return 'Efectivo';
      case 'CHEQUE':
        return 'Cheque';
      default:
        return 'Otro';
    }
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
