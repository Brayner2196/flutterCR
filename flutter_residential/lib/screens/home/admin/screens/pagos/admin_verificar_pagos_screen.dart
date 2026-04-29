import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/pago_model.dart';
import '../../../../../providers/pagos_provider.dart';
import '../../../../../theme/app_theme.dart';

class AdminVerificarPagosScreen extends StatefulWidget {
  const AdminVerificarPagosScreen({super.key});

  @override
  State<AdminVerificarPagosScreen> createState() =>
      _AdminVerificarPagosScreenState();
}

class _AdminVerificarPagosScreenState extends State<AdminVerificarPagosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _cargar() {
    if (!mounted) return;
    context.read<PagosProvider>().cargarTodosPagosAdmin();
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
            onPressed: _cargar,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Pendientes'),
                if (provider.pendientes.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _Badge(
                      count: provider.pendientes.length,
                      color: AppColors.yellow),
                ],
              ]),
            ),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Verificados'),
                if (provider.verificados.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _Badge(
                      count: provider.verificados.length,
                      color: AppColors.ok),
                ],
              ]),
            ),
            Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Rechazados'),
                if (provider.rechazados.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _Badge(
                      count: provider.rechazados.length,
                      color: AppColors.danger),
                ],
              ]),
            ),
          ],
        ),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _ErrorView(
                  mensaje: provider.error!,
                  onReintentar: _cargar,
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _ListaPagos(
                      pagos: provider.pendientes,
                      emptyMessage:
                          'No hay pagos pendientes de verificación',
                      emptyIcon: Icons.task_alt,
                      emptyColor: AppColors.ok,
                      onVerificar: (p) => _verificar(context, p),
                      onRechazar: (p) => _rechazar(context, p),
                      mostrarAcciones: true,
                    ),
                    _ListaPagos(
                      pagos: provider.verificados,
                      emptyMessage: 'Sin pagos verificados',
                      emptyIcon: Icons.check_circle_outline,
                      emptyColor: AppColors.ok,
                    ),
                    _ListaPagos(
                      pagos: provider.rechazados,
                      emptyMessage: 'Sin pagos rechazados',
                      emptyIcon: Icons.cancel_outlined,
                      emptyColor: AppColors.danger,
                    ),
                  ],
                ),
    );
  }

  Future<void> _verificar(BuildContext context, PagoModel pago) async {
    try {
      await context.read<PagosProvider>().verificar(pago.id);
      if (mounted) _cargar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pago verificado correctamente'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _rechazar(BuildContext context, PagoModel pago) async {
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
            autofocus: true,
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
      if (mounted) _cargar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pago rechazado'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}

// ─── Componentes internos ──────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _ErrorView({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 52, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaPagos extends StatelessWidget {
  final List<PagoModel> pagos;
  final String emptyMessage;
  final IconData emptyIcon;
  final Color emptyColor;
  final void Function(PagoModel)? onVerificar;
  final void Function(PagoModel)? onRechazar;
  final bool mostrarAcciones;

  const _ListaPagos({
    required this.pagos,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.emptyColor,
    this.onVerificar,
    this.onRechazar,
    this.mostrarAcciones = false,
  });

  @override
  Widget build(BuildContext context) {
    if (pagos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 52, color: emptyColor),
            const SizedBox(height: 12),
            Text(emptyMessage,
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                    fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: pagos.length,
      itemBuilder: (_, i) => _PagoVerificacionCard(
        pago: pagos[i],
        onVerificar: mostrarAcciones ? onVerificar : null,
        onRechazar: mostrarAcciones ? onRechazar : null,
      ),
    );
  }
}

class _PagoVerificacionCard extends StatelessWidget {
  final PagoModel pago;
  final void Function(PagoModel)? onVerificar;
  final void Function(PagoModel)? onRechazar;
  const _PagoVerificacionCard(
      {required this.pago, this.onVerificar, this.onRechazar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color estadoColor;
    final String estadoLabel;
    if (pago.esVerificado) {
      estadoColor = AppColors.ok;
      estadoLabel = 'Verificado';
    } else if (pago.esRechazado) {
      estadoColor = AppColors.danger;
      estadoLabel = 'Rechazado';
    } else {
      estadoColor = AppColors.yellow;
      estadoLabel = 'Pendiente';
    }

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
                Expanded(
                  child: Text(pago.usuarioNombre,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: cs.onSurface)),
                ),
                Text(_fmt(pago.montoPagado),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: cs.primary)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                    '${pago.metodoPago} · ${pago.fechaPago}',
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 12)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: estadoColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(estadoLabel,
                      style: TextStyle(
                          color: estadoColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (pago.referencia != null) ...[
              const SizedBox(height: 2),
              Text('Ref: ${pago.referencia}',
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontSize: 12)),
            ],
            if (pago.esRechazado && pago.motivoRechazo != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.danger, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pago.motivoRechazo!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onVerificar != null && onRechazar != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(
                              color: AppColors.danger)),
                      onPressed: () => onRechazar!(pago),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => onVerificar!(pago),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Verificar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  const _Badge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(10)),
      child: Text('$count',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}
