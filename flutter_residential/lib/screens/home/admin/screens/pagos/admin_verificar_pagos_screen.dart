import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/abono_model.dart';
import '../../../../../models/pago_model.dart';
import '../../../../../providers/abono_provider.dart';
import '../../../../../providers/pagos_provider.dart';
import '../../../../../shared/theme/app_theme.dart';

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
    _tabs = TabController(length: 4, vsync: this);
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
    context.read<AbonoProvider>().cargarTodosAbonosAdmin();
  }

  @override
  Widget build(BuildContext context) {
    final pagosProvider = context.watch<PagosProvider>();
    final abonosProvider = context.watch<AbonoProvider>();
    final cargando = pagosProvider.loading || abonosProvider.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Pagos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Pagos'),
              if (pagosProvider.pendientes.isNotEmpty) ...[
                const SizedBox(width: 6),
                _Badge(count: pagosProvider.pendientes.length, color: AppColors.yellow),
              ],
            ])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Abonos'),
              if (abonosProvider.pendientes.isNotEmpty) ...[
                const SizedBox(width: 6),
                _Badge(count: abonosProvider.pendientes.length, color: Colors.blue),
              ],
            ])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Verificados'),
              if (pagosProvider.verificados.isNotEmpty || abonosProvider.verificados.isNotEmpty) ...[
                const SizedBox(width: 6),
                _Badge(
                    count: pagosProvider.verificados.length + abonosProvider.verificados.length,
                    color: AppColors.ok),
              ],
            ])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Rechazados'),
              if (pagosProvider.rechazados.isNotEmpty || abonosProvider.rechazados.isNotEmpty) ...[
                const SizedBox(width: 6),
                _Badge(
                    count: pagosProvider.rechazados.length + abonosProvider.rechazados.length,
                    color: AppColors.danger),
              ],
            ])),
          ],
        ),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                // Tab 0 — Pagos pendientes
                _ListaPagos(
                  pagos: pagosProvider.pendientes,
                  emptyMessage: 'No hay pagos pendientes',
                  emptyIcon: Icons.task_alt,
                  emptyColor: AppColors.ok,
                  onVerificar: (p) => _verificar(context, p),
                  onRechazar: (p) => _rechazar(context, p),
                  mostrarAcciones: true,
                ),
                // Tab 1 — Abonos pendientes
                _ListaAbonos(
                  abonos: abonosProvider.pendientes,
                  emptyMessage: 'No hay abonos pendientes',
                  emptyIcon: Icons.savings_outlined,
                  emptyColor: Colors.blue,
                  onVerificar: (a) => _verificarAbono(context, a),
                  onRechazar: (a) => _rechazarAbono(context, a),
                  mostrarAcciones: true,
                ),
                // Tab 2 — Verificados (pagos + abonos)
                _TabVerificados(
                  pagos: pagosProvider.verificados,
                  abonos: abonosProvider.verificados,
                ),
                // Tab 3 — Rechazados (pagos + abonos)
                _TabVerificados(
                  pagos: pagosProvider.rechazados,
                  abonos: abonosProvider.rechazados,
                  esRechazado: true,
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
    final motivo = await _dialogMotivo(context, 'Rechazar pago');
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

  Future<void> _verificarAbono(BuildContext context, AbonoModel abono) async {
    try {
      await context.read<AbonoProvider>().verificar(abono.id);
      if (mounted) _cargar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Abono verificado y distribuido correctamente'),
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

  Future<void> _rechazarAbono(BuildContext context, AbonoModel abono) async {
    final motivo = await _dialogMotivo(context, 'Rechazar abono');
    if (motivo == null || motivo.trim().isEmpty) return;
    try {
      await context.read<AbonoProvider>().rechazar(abono.id, motivo);
      if (mounted) _cargar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Abono rechazado'),
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

  Future<String?> _dialogMotivo(BuildContext context, String titulo) =>
      showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: Text(titulo),
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

// ─── Lista de abonos ───────────────────────────────────────────────

class _ListaAbonos extends StatelessWidget {
  final List<AbonoModel> abonos;
  final String emptyMessage;
  final IconData emptyIcon;
  final Color emptyColor;
  final void Function(AbonoModel)? onVerificar;
  final void Function(AbonoModel)? onRechazar;
  final bool mostrarAcciones;

  const _ListaAbonos({
    required this.abonos,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.emptyColor,
    this.onVerificar,
    this.onRechazar,
    this.mostrarAcciones = false,
  });

  @override
  Widget build(BuildContext context) {
    if (abonos.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(emptyIcon, size: 52, color: emptyColor),
          const SizedBox(height: 12),
          Text(emptyMessage,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: abonos.length,
      itemBuilder: (_, i) => _AbonoVerificacionCard(
        abono: abonos[i],
        onVerificar: mostrarAcciones ? onVerificar : null,
        onRechazar: mostrarAcciones ? onRechazar : null,
      ),
    );
  }
}

class _AbonoVerificacionCard extends StatelessWidget {
  final AbonoModel abono;
  final void Function(AbonoModel)? onVerificar;
  final void Function(AbonoModel)? onRechazar;
  const _AbonoVerificacionCard(
      {required this.abono, this.onVerificar, this.onRechazar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color estadoColor = abono.esVerificado
        ? AppColors.ok
        : abono.esRechazado
            ? AppColors.danger
            : Colors.blue;
    final String estadoLabel = abono.esVerificado
        ? 'Verificado'
        : abono.esRechazado
            ? 'Rechazado'
            : 'Pendiente';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(children: [
                  const Icon(Icons.savings_outlined, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(abono.usuarioNombre,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: cs.onSurface)),
                  ),
                ]),
              ),
              Text(_fmt(abono.montoTotal),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 4),
          Row(children: [
            Text('${abono.metodoPago} · ${abono.fechaPago}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: estadoColor.withValues(alpha: 0.4)),
              ),
              child: Text(estadoLabel,
                  style: TextStyle(
                      color: estadoColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          if (abono.referencia != null) ...[
            const SizedBox(height: 2),
            Text('Ref: ${abono.referencia}',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
          // Distribución FIFO ya aplicada
          if (abono.esVerificado && abono.movimientos.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...abono.movimientos.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Icon(
                      m.esSaldoFavor
                          ? Icons.savings_outlined
                          : Icons.check_circle_outline,
                      size: 14,
                      color: m.esSaldoFavor ? Colors.teal : Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(m.descripcion,
                            style: const TextStyle(fontSize: 12))),
                    Text(_fmt(m.montoAplicado),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                )),
          ],
          if (abono.esRechazado && abono.motivoRechazo != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    color: AppColors.danger, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(abono.motivoRechazo!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12)),
                ),
              ]),
            ),
          ],
          if (onVerificar != null && onRechazar != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger)),
                  onPressed: () => onRechazar!(abono),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () => onVerificar!(abono),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Verificar'),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

// ─── Tab combinado verificados/rechazados ─────────────────────────

class _TabVerificados extends StatelessWidget {
  final List<PagoModel> pagos;
  final List<AbonoModel> abonos;
  final bool esRechazado;
  const _TabVerificados(
      {required this.pagos,
      required this.abonos,
      this.esRechazado = false});

  @override
  Widget build(BuildContext context) {
    if (pagos.isEmpty && abonos.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            esRechazado ? Icons.cancel_outlined : Icons.check_circle_outline,
            size: 52,
            color: esRechazado ? AppColors.danger : AppColors.ok,
          ),
          const SizedBox(height: 12),
          Text(
            esRechazado ? 'Sin rechazados' : 'Sin verificados',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16),
          ),
        ]),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (pagos.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Pagos',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ...pagos.map((p) => _PagoVerificacionCard(pago: p)),
        ],
        if (abonos.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(top: pagos.isNotEmpty ? 12 : 0, bottom: 8),
            child: Text('Abonos',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          ...abonos.map((a) => _AbonoVerificacionCard(abono: a)),
        ],
      ],
    );
  }
}
