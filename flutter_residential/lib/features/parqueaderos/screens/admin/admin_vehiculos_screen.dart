import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../providers/vehiculo_provider.dart';
import '../../widgets/vehiculo_card.dart';
import '../../models/vehiculo_model.dart';

/// Tab de gestión de vehículos para TENANT_ADMIN.
/// Se embebe dentro de AdminParqueaderosScreen como tercer tab.
class AdminVehiculosTab extends StatefulWidget {
  const AdminVehiculosTab({super.key});

  @override
  State<AdminVehiculosTab> createState() => _AdminVehiculosTabState();
}

class _AdminVehiculosTabState extends State<AdminVehiculosTab> {
  bool _soloPendientes = false;

  Future<void> _aplicarFiltro(bool soloPendientes) async {
    setState(() => _soloPendientes = soloPendientes);
    await context.read<VehiculoProvider>().cargarAdmin(soloPendientes: soloPendientes);
  }

  Future<void> _aprobar(VehiculoModel v) async {
    try {
      await context.read<VehiculoProvider>().aprobar(v.id);
      if (!mounted) return;
      _toast(ToastificationType.success, 'Vehículo aprobado');
    } catch (e) {
      if (!mounted) return;
      _toast(ToastificationType.error, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _rechazar(VehiculoModel v) async {
    final motivo = await _pedirMotivo();
    if (motivo == null || !mounted) return;
    try {
      await context.read<VehiculoProvider>().rechazar(v.id, motivo: motivo.isNotEmpty ? motivo : null);
      if (!mounted) return;
      _toast(ToastificationType.success, 'Vehículo rechazado');
    } catch (e) {
      if (!mounted) return;
      _toast(ToastificationType.error, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<String?> _pedirMotivo() => showDialog<String>(
        context: context,
        builder: (_) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: const Text('Motivo del rechazo'),
            content: TextField(
              controller: ctrl,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Opcional — describe el motivo',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                child: const Text('Rechazar'),
              ),
            ],
          );
        },
      );

  void _toast(ToastificationType tipo, String msg) {
    toastification.show(
      context: context,
      type: tipo,
      title: Text(msg),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiculoProvider>();
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () =>
          context.read<VehiculoProvider>().cargarAdmin(soloPendientes: _soloPendientes),
      child: CustomScrollView(
        slivers: [
          // ── Filtros ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  _FiltroChip(
                    label: 'Pendientes',
                    activo: _soloPendientes,
                    onTap: () => _aplicarFiltro(true),
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Todos',
                    activo: !_soloPendientes,
                    onTap: () => _aplicarFiltro(false),
                  ),
                ],
              ),
            ),
          ),

          // ── Loading ───────────────────────────────────────────────
          if (p.loading && p.vehiculos.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )

          // ── Vacío ─────────────────────────────────────────────────
          else if (p.vehiculos.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car_outlined,
                        size: 48, color: cs.outline),
                    const SizedBox(height: 12),
                    Text(
                      _soloPendientes
                          ? 'Sin vehículos pendientes'
                          : 'No hay vehículos registrados',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )

          // ── Lista ─────────────────────────────────────────────────
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              sliver: SliverList.separated(
                itemCount: p.vehiculos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final v = p.vehiculos[i];
                  return VehiculoCard(
                    vehiculo: v,
                    onAprobar: v.esPendiente ? () => _aprobar(v) : null,
                    onRechazar: v.esPendiente ? () => _rechazar(v) : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Chip de filtro ──────────────────────────────────────────────────────────

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? cs.primary : cs.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: activo ? Colors.white : cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
