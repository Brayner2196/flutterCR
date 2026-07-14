import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/presupuesto_model.dart';
import '../../providers/presupuesto_provider.dart';
import 'admin_detalle_presupuesto_screen.dart';
import 'admin_form_presupuesto_screen.dart';

/// Lista de todos los presupuestos del conjunto.
class AdminPresupuestosScreen extends StatefulWidget {
  const AdminPresupuestosScreen({super.key});

  @override
  State<AdminPresupuestosScreen> createState() => _AdminPresupuestosScreenState();
}

class _AdminPresupuestosScreenState extends State<AdminPresupuestosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresupuestoProvider>().cargarListaAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PresupuestoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presupuestos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo presupuesto',
            onPressed: () => _abrirFormulario(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<PresupuestoProvider>().cargarListaAdmin(),
        child: Builder(builder: (_) {
          if (p.loading && p.presupuestos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (p.presupuestos.isEmpty) {
            return _EmptyState(onCrear: () => _abrirFormulario(context));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: p.presupuestos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _PresupuestoTile(
              presupuesto: p.presupuestos[i],
              onTap: () => _abrirDetalle(context, p.presupuestos[i].id),
              onToggleActivo: (val) => _toggleActivo(context, p.presupuestos[i], val),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _abrirFormulario(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminFormPresupuestoScreen()),
    );
    if (!context.mounted) return;
    context.read<PresupuestoProvider>().cargarListaAdmin();
  }

  Future<void> _abrirDetalle(BuildContext context, int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminDetallePresupuestoScreen(id: id)),
    );
    if (!context.mounted) return;
    context.read<PresupuestoProvider>().cargarListaAdmin();
  }

  Future<void> _toggleActivo(
      BuildContext context, PresupuestoModel p, bool activo) async {
    try {
      await context.read<PresupuestoProvider>().toggleActivo(p.id, activo: activo);
      if (context.mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: Text(activo
              ? 'Presupuesto ${p.anio} activado'
              : 'Presupuesto ${p.anio} desactivado'),
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

// ── Tile de presupuesto ────────────────────────────────────────────────────────
class _PresupuestoTile extends StatelessWidget {
  final PresupuestoModel presupuesto;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActivo;

  const _PresupuestoTile({
    required this.presupuesto,
    required this.onTap,
    required this.onToggleActivo,
  });

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = presupuesto;
    final pct = p.porcentajeEjecucionGeneral.clamp(0.0, 100.0) / 100;
    final Color barColor = p.tieneExcedidos ? AppColors.danger : AppColors.ok;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: p.activo
                ? AppColors.blue.withValues(alpha: 0.5)
                : cs.outlineVariant,
            width: p.activo ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.titulo?.isNotEmpty == true
                            ? p.titulo!
                            : 'Presupuesto ${p.anio}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text('Año ${p.anio}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (p.activo)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.bgBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Activo',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue)),
                  ),
                const SizedBox(width: 8),
                Switch(
                  value: p.activo,
                  onChanged: onToggleActivo,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Montos ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MontoChip('Presupuestado', _fmt(p.montoTotalPresupuestado),
                    cs.onSurfaceVariant),
                _MontoChip(
                    'Ejecutado', _fmt(p.montoTotalEjecutado), barColor),
                _MontoChip('Disponible',
                    _fmt(p.montoTotalPendiente.clamp(0, double.infinity)),
                    cs.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 8),

            // ── Barra de progreso ──────────────────────────────
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
              '${p.porcentajeEjecucionGeneral.toStringAsFixed(1)}% ejecutado · ${p.categorias.length} categoría${p.categorias.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MontoChip extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  const _MontoChip(this.label, this.valor, this.color);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(valor,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      );
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onCrear;
  const _EmptyState({required this.onCrear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_outlined, size: 56, color: cs.outline),
            const SizedBox(height: 16),
            Text('Sin presupuestos',
                style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Crea el primer presupuesto anual del conjunto.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add),
              label: const Text('Crear presupuesto'),
            ),
          ],
        ),
      ),
    );
  }
}
