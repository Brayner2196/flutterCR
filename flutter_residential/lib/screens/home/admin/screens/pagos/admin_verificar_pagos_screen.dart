import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/pago_model.dart';
import '../../../../../providers/pagos_provider.dart';

class AdminVerificarPagosScreen extends StatefulWidget {
  const AdminVerificarPagosScreen({super.key});

  @override
  State<AdminVerificarPagosScreen> createState() =>
      _AdminVerificarPagosScreenState();
}

class _AdminVerificarPagosScreenState
    extends State<AdminVerificarPagosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<PagosProvider>().cargarPagosAdmin());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PagosProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Pagos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<PagosProvider>().cargarPagosAdmin(),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.pendientes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt,
                          size: 52, color: Colors.green),
                      SizedBox(height: 12),
                      Text('No hay pagos pendientes',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.pendientes.length,
                  itemBuilder: (_, i) =>
                      _PagoVerificacionCard(
                          pago: provider.pendientes[i]),
                ),
    );
  }
}

class _PagoVerificacionCard extends StatelessWidget {
  final PagoModel pago;
  const _PagoVerificacionCard({required this.pago});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(pago.usuarioNombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Text(_fmt(pago.montoPagado),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                '${pago.metodoPago} · ${pago.fechaPago}',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
            if (pago.referencia != null)
              Text('Ref: ${pago.referencia}',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
            if (pago.urlComprobante != null) ...[              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.attachment, size: 16),
                label: Text('Ver comprobante',
                    style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize:
                        MaterialTapTargetSize.shrinkWrap),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red),
                    onPressed: () =>
                        _rechazar(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _verificar(context),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Verificar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verificar(BuildContext context) async {
    try {
      await context.read<PagosProvider>().verificar(pago.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pago verificado correctamente'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _rechazar(BuildContext context) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Rechazar pago'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
                hintText: 'Motivo del rechazo',
                border: OutlineInputBorder()),
            maxLines: 2,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: const Text('Rechazar')),
          ],
        );
      },
    );
    if (motivo == null || motivo.trim().isEmpty) return;
    try {
      await context.read<PagosProvider>().rechazar(pago.id, motivo);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pago rechazado'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}
