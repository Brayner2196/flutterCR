import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/categoria_presupuesto_model.dart';
import '../../models/gasto_registrado_model.dart';
import '../../models/presupuesto_model.dart';
import '../../providers/presupuesto_provider.dart';
import 'admin_form_presupuesto_screen.dart';

/// Detalle de un presupuesto: resumen general + categorías con barra de ejecución + gastos.
class AdminDetallePresupuestoScreen extends StatefulWidget {
  final int id;
  const AdminDetallePresupuestoScreen({super.key, required this.id});

  @override
  State<AdminDetallePresupuestoScreen> createState() =>
      _AdminDetallePresupuestoScreenState();
}

class _AdminDetallePresupuestoScreenState
    extends State<AdminDetallePresupuestoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresupuestoProvider>().cargarDetalle(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PresupuestoProvider>();

    if (prov.loading && prov.detalle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Presupuesto')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final p = prov.detalle;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Presupuesto')),
        body: const Center(child: Text('No se pudo cargar el presupuesto')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(p.titulo?.isNotEmpty == true ? p.titulo! : 'Presupuesto ${p.anio}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AdminFormPresupuestoScreen(presupuesto: p)),
            ).then((_) =>
                context.read<PresupuestoProvider>().cargarDetalle(widget.id)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<PresupuestoProvider>().cargarDetalle(widget.id),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Resumen general ────────────────────────────
            _ResumenCard(presupuesto: p),
            const SizedBox(height: 20),

            // ── Categorías ─────────────────────────────────
            _SectionLabel('Categorías'),
            const SizedBox(height: 8),
            ...p.categorias.map((c) => _CategoriaCard(
                  categoria: c,
                  presupuestoId: p.id,
                  onRegistrarGasto: () => _registrarGasto(context, p, c),
                  onEliminarGasto: (g) => _eliminarGasto(context, p.id, g),
                )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _registrarGasto(context, p, null),
        icon: const Icon(Icons.add),
        label: const Text('Registrar gasto'),
      ),
    );
  }

  // ── Registrar gasto ──────────────────────────────────────────────

  void _registrarGasto(
      BuildContext context, PresupuestoModel p, CategoriaPresupuestoModel? categoriaPreseleccionada) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RegistrarGastoSheet(
        presupuesto: p,
        categoriaInicial: categoriaPreseleccionada,
        onGuardar: (body) async {
          await context
              .read<PresupuestoProvider>()
              .registrarGasto(p.id, body);
          if (context.mounted) {
            Navigator.pop(context);
            toastification.show(
              context: context,
              type: ToastificationType.success,
              title: const Text('Gasto registrado'),
              autoCloseDuration: const Duration(seconds: 2),
            );
          }
        },
      ),
    );
  }

  // ── Eliminar gasto ───────────────────────────────────────────────

  Future<void> _eliminarGasto(
      BuildContext context, int presupuestoId, GastoRegistradoModel g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text(
            '¿Eliminar "${g.descripcion}" por \$${g.monto.toStringAsFixed(0)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<PresupuestoProvider>().eliminarGasto(presupuestoId, g.id);
      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('Gasto eliminado'),
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text(e.toString().replaceFirst('Exception: ', '')),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }
}

// ── Resumen general ───────────────────────────────────────────────────────────

class _ResumenCard extends StatelessWidget {
  final PresupuestoModel presupuesto;
  const _ResumenCard({required this.presupuesto});

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = presupuesto;
    final pct = (p.porcentajeEjecucionGeneral / 100).clamp(0.0, 1.0);
    final barColor = p.tieneExcedidos ? AppColors.danger : AppColors.ok;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total presupuestado',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              Text(_fmt(p.montoTotalPresupuestado),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ejecutado: ${_fmt(p.montoTotalEjecutado)}',
                  style: TextStyle(fontSize: 12, color: barColor)),
              Text(
                'Disponible: ${_fmt(p.montoTotalPendiente.clamp(0, double.infinity))}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${p.porcentajeEjecucionGeneral.toStringAsFixed(1)}% de ejecución general',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          if (p.tieneExcedidos) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    size: 14, color: AppColors.danger),
                const SizedBox(width: 6),
                Text('Hay categorías que exceden el presupuesto',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.danger)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Categoría card ────────────────────────────────────────────────────────────

class _CategoriaCard extends StatefulWidget {
  final CategoriaPresupuestoModel categoria;
  final int presupuestoId;
  final VoidCallback onRegistrarGasto;
  final ValueChanged<GastoRegistradoModel> onEliminarGasto;

  const _CategoriaCard({
    required this.categoria,
    required this.presupuestoId,
    required this.onRegistrarGasto,
    required this.onEliminarGasto,
  });

  @override
  State<_CategoriaCard> createState() => _CategoriaCardState();
}

class _CategoriaCardState extends State<_CategoriaCard> {
  bool _expandido = false;

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = widget.categoria;
    final pct = (c.porcentajeEjecucion / 100).clamp(0.0, 1.0);
    final Color barColor = c.excedida ? AppColors.danger : AppColors.ok;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: c.excedida
              ? AppColors.danger.withValues(alpha: 0.4)
              : cs.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          // ── Cabecera ─────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(c.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        color: AppColors.blue,
                        tooltip: 'Registrar gasto',
                        onPressed: widget.onRegistrarGasto,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expandido
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Asignado: ${_fmt(c.montoAsignado)}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                      Text('Ejecutado: ${_fmt(c.montoEjecutado)}',
                          style: TextStyle(fontSize: 12, color: barColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: cs.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.porcentajeEjecucion.toStringAsFixed(1)}%${c.excedida ? ' — EXCEDIDA' : ''}',
                    style: TextStyle(fontSize: 11, color: barColor),
                  ),
                ],
              ),
            ),
          ),

          // ── Gastos expandidos ─────────────────────────────
          if (_expandido) ...[
            const Divider(height: 1),
            if (c.gastos.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Sin gastos registrados',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
              )
            else
              ...c.gastos.map((g) => _GastoTile(
                    gasto: g,
                    onEliminar: () => widget.onEliminarGasto(g),
                  )),
          ],
        ],
      ),
    );
  }
}

// ── Tile de gasto ─────────────────────────────────────────────────────────────

class _GastoTile extends StatelessWidget {
  final GastoRegistradoModel gasto;
  final VoidCallback onEliminar;

  const _GastoTile({required this.gasto, required this.onEliminar});

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gasto.descripcion,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                Text(gasto.fecha,
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(_fmt(gasto.monto),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: AppColors.danger,
            onPressed: onEliminar,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Sheet registrar gasto ─────────────────────────────────────────────────────

class _RegistrarGastoSheet extends StatefulWidget {
  final PresupuestoModel presupuesto;
  final CategoriaPresupuestoModel? categoriaInicial;
  final Future<void> Function(Map<String, dynamic> body) onGuardar;

  const _RegistrarGastoSheet({
    required this.presupuesto,
    this.categoriaInicial,
    required this.onGuardar,
  });

  @override
  State<_RegistrarGastoSheet> createState() => _RegistrarGastoSheetState();
}

class _RegistrarGastoSheetState extends State<_RegistrarGastoSheet> {
  late int? _categoriaId;
  final _descCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  late String _fecha;
  final _comprobanteCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _categoriaId = widget.categoriaInicial?.id;
    _fecha = DateTime.now().toIso8601String().substring(0, 10);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _montoCtrl.dispose();
    _comprobanteCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_fecha),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _fecha = picked.toIso8601String().substring(0, 10));
    }
  }

  Future<void> _guardar() async {
    if (_categoriaId == null) {
      _toast('Selecciona una categoría');
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      _toast('Ingresa una descripción');
      return;
    }
    final monto = double.tryParse(_montoCtrl.text.trim());
    if (monto == null || monto <= 0) {
      _toast('Ingresa un monto válido');
      return;
    }

    setState(() => _guardando = true);
    try {
      await widget.onGuardar({
        'categoriaId': _categoriaId,
        'descripcion': _descCtrl.text.trim(),
        'monto': monto,
        'fecha': _fecha,
        'comprobante': _comprobanteCtrl.text.trim().isEmpty
            ? null
            : _comprobanteCtrl.text.trim(),
      });
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _toast(String msg) {
    toastification.show(
      context: context,
      type: ToastificationType.warning,
      title: Text(msg),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registrar gasto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // ── Categoría ──────────────────────────────────────
          DropdownButtonFormField<int>(
            initialValue: _categoriaId,
            decoration: InputDecoration(
              labelText: 'Categoría *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            items: widget.presupuesto.categorias
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
                .toList(),
            onChanged: (v) => setState(() => _categoriaId = v),
          ),
          const SizedBox(height: 12),

          // ── Descripción ─────────────────────────────────────
          TextField(
            controller: _descCtrl,
            decoration: InputDecoration(
              labelText: 'Descripción *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // ── Monto y fecha ───────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _montoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Monto *',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _seleccionarFecha,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fecha *',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                      suffixIcon: const Icon(Icons.calendar_today_outlined,
                          size: 16),
                    ),
                    child: Text(_fecha,
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Comprobante ─────────────────────────────────────
          TextField(
            controller: _comprobanteCtrl,
            decoration: InputDecoration(
              labelText: 'Comprobante (opcional)',
              hintText: 'URL o referencia de factura',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),

          // ── Botón ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_outlined),
              label: Text(_guardando ? 'Guardando...' : 'Registrar'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ));
}
