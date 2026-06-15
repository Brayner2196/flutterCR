import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../models/vehiculo_model.dart';
import '../../providers/parqueadero_provider.dart';
import '../../providers/vehiculo_provider.dart';
import '../../widgets/parqueadero_card.dart';
import '../../widgets/vehiculo_card.dart';

/// Pantalla de parqueaderos para PROPIETARIO / INQUILINO.
/// Dos tabs: Mis Vehículos y Mis Parqueaderos asignados.
///
/// Árbol:
/// ResidenteHomeScreen → ResidenteDashboardScreen (QuickAccess)
///   → MisParqueaderosResidenteScreen
class MisParqueaderosResidenteScreen extends StatefulWidget {
  final int propiedadId;

  const MisParqueaderosResidenteScreen({
    super.key,
    required this.propiedadId,
  });

  @override
  State<MisParqueaderosResidenteScreen> createState() =>
      _MisParqueaderosResidenteScreenState();
}

class _MisParqueaderosResidenteScreenState
    extends State<MisParqueaderosResidenteScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehiculoProvider>().cargarMisVehiculos(widget.propiedadId);
      context
          .read<ParqueaderoProvider>()
          .cargarMisParqueaderos(widget.propiedadId);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parqueaderos'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Mis Vehículos'),
            Tab(text: 'Mis Parqueaderos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _TabMisVehiculos(propiedadId: widget.propiedadId),
          _TabMisParqueaderos(propiedadId: widget.propiedadId),
        ],
      ),
      // FAB para registrar vehículo (solo en tab de vehículos)
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, __) => _tabCtrl.index == 0
            ? FloatingActionButton.extended(
                onPressed: () => _mostrarRegistrarSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Registrar vehículo'),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  void _mostrarRegistrarSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RegistrarVehiculoSheet(
        propiedadId: widget.propiedadId,
        onRegistrar: (data) async {
          try {
            await context
                .read<VehiculoProvider>()
                .registrar(data, widget.propiedadId);
            if (!context.mounted) return;
            Navigator.pop(context);
            toastification.show(
              context: context,
              type: ToastificationType.success,
              title: const Text('Vehículo registrado. Pendiente de aprobación.'),
              autoCloseDuration: const Duration(seconds: 4),
            );
          } catch (e) {
            if (!context.mounted) return;
            toastification.show(
              context: context,
              type: ToastificationType.error,
              title: Text(e.toString().replaceFirst('Exception: ', '')),
              autoCloseDuration: const Duration(seconds: 3),
            );
          }
        },
      ),
    );
  }
}

// ─── Tab Mis Vehículos ───────────────────────────────────────────────────────

class _TabMisVehiculos extends StatelessWidget {
  final int propiedadId;

  const _TabMisVehiculos({required this.propiedadId});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<VehiculoProvider>();
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => context.read<VehiculoProvider>().cargarMisVehiculos(propiedadId),
      child: CustomScrollView(
        slivers: [
          // ── Aviso aprobación ─────────────────────────────────────
          if (p.vehiculos.any((v) => v.esPendiente))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tienes vehículos pendientes de aprobación por el administrador.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
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
                      'No tienes vehículos registrados',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Usa el botón "+" para agregar uno',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )

          // ── Lista ─────────────────────────────────────────────────
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
              sliver: SliverList.separated(
                itemCount: p.vehiculos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final v = p.vehiculos[i];
                  return VehiculoCard(
                    vehiculo: v,
                    onEliminar: () => _confirmarEliminar(ctx, v, propiedadId),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _confirmarEliminar(
      BuildContext context, VehiculoModel v, int propiedadId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text('¿Eliminar el vehículo "${v.placa}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context
                    .read<VehiculoProvider>()
                    .eliminarVehiculo(v.id, propiedadId);
                if (!context.mounted) return;
                toastification.show(
                  context: context,
                  type: ToastificationType.success,
                  title: const Text('Vehículo eliminado'),
                  autoCloseDuration: const Duration(seconds: 3),
                );
              } catch (e) {
                if (!context.mounted) return;
                toastification.show(
                  context: context,
                  type: ToastificationType.error,
                  title: Text(e.toString().replaceFirst('Exception: ', '')),
                  autoCloseDuration: const Duration(seconds: 3),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Mis Parqueaderos ────────────────────────────────────────────────────

class _TabMisParqueaderos extends StatelessWidget {
  final int propiedadId;

  const _TabMisParqueaderos({required this.propiedadId});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParqueaderoProvider>();
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () =>
          context.read<ParqueaderoProvider>().cargarMisParqueaderos(propiedadId),
      child: CustomScrollView(
        slivers: [
          if (p.loading && p.parqueaderos.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (p.parqueaderos.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_parking, size: 48, color: cs.outline),
                    const SizedBox(height: 12),
                    Text(
                      'No tienes parqueaderos asignados',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList.separated(
                itemCount: p.parqueaderos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final parq = p.parqueaderos[i];
                  final vehiculos = context.read<VehiculoProvider>().vehiculos
                      .where((v) => v.esAprobado)
                      .toList();
                  return ParqueaderoCard(
                    parqueadero: parq,
                    onCambiarVehiculo: () => _cambiarVehiculo(ctx, parq.id, vehiculos, propiedadId),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _cambiarVehiculo(
    BuildContext context,
    int parqueaderoId,
    List<VehiculoModel> vehiculosAprobados,
    int propiedadId,
  ) {
    showDialog(
      context: context,
      builder: (_) => _CambiarVehiculoDialog(
        vehiculos: vehiculosAprobados,
        onSeleccionar: (vehiculoId) async {
          try {
            await context
                .read<ParqueaderoProvider>()
                .cambiarVehiculo(parqueaderoId, vehiculoId, propiedadId);
            if (!context.mounted) return;
            Navigator.pop(context);
            toastification.show(
              context: context,
              type: ToastificationType.success,
              title: const Text('Vehículo actualizado'),
              autoCloseDuration: const Duration(seconds: 3),
            );
          } catch (e) {
            if (!context.mounted) return;
            toastification.show(
              context: context,
              type: ToastificationType.error,
              title: Text(e.toString().replaceFirst('Exception: ', '')),
              autoCloseDuration: const Duration(seconds: 3),
            );
          }
        },
      ),
    );
  }
}

// ─── Sheet registrar vehículo ────────────────────────────────────────────────

class _RegistrarVehiculoSheet extends StatefulWidget {
  final int propiedadId;
  final Future<void> Function(Map<String, dynamic>) onRegistrar;

  const _RegistrarVehiculoSheet({
    required this.propiedadId,
    required this.onRegistrar,
  });

  @override
  State<_RegistrarVehiculoSheet> createState() => _RegistrarVehiculoSheetState();
}

class _RegistrarVehiculoSheetState extends State<_RegistrarVehiculoSheet> {
  final _placaCtrl  = TextEditingController();
  final _marcaCtrl  = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _colorCtrl  = TextEditingController();

  TipoVehiculo _tipo = TipoVehiculo.CARRO;
  bool _cargando = false;

  @override
  void dispose() {
    _placaCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar vehículo',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Tipo
            DropdownButtonFormField<TipoVehiculo>(
              value: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo de vehículo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: TipoVehiculo.CARRO, child: Text('Carro')),
                DropdownMenuItem(
                    value: TipoVehiculo.MOTO, child: Text('Moto')),
                DropdownMenuItem(
                    value: TipoVehiculo.BICICLETA, child: Text('Bicicleta')),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 12),

            // Placa
            TextField(
              controller: _placaCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Placa *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Marca
            TextField(
              controller: _marcaCtrl,
              decoration: const InputDecoration(
                labelText: 'Marca',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Modelo
            TextField(
              controller: _modeloCtrl,
              decoration: const InputDecoration(
                labelText: 'Modelo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Color
            TextField(
              controller: _colorCtrl,
              decoration: const InputDecoration(
                labelText: 'Color',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _placaCtrl,
              builder: (_, value, __) {
                final valido = value.text.trim().isNotEmpty;
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: valido && !_cargando
                        ? () async {
                            setState(() => _cargando = true);
                            await widget.onRegistrar({
                              'placa':  _placaCtrl.text.trim().toUpperCase(),
                              'tipo':   _tipo.name,
                              'marca':  _marcaCtrl.text.trim().isEmpty ? null : _marcaCtrl.text.trim(),
                              'modelo': _modeloCtrl.text.trim().isEmpty ? null : _modeloCtrl.text.trim(),
                              'color':  _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
                            });
                            if (mounted) setState(() => _cargando = false);
                          }
                        : null,
                    child: _cargando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Registrar'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dialog cambiar vehículo ─────────────────────────────────────────────────

class _CambiarVehiculoDialog extends StatefulWidget {
  final List<VehiculoModel> vehiculos;
  final Future<void> Function(int? vehiculoId) onSeleccionar;

  const _CambiarVehiculoDialog({
    required this.vehiculos,
    required this.onSeleccionar,
  });

  @override
  State<_CambiarVehiculoDialog> createState() => _CambiarVehiculoDialogState();
}

class _CambiarVehiculoDialogState extends State<_CambiarVehiculoDialog> {
  int? _seleccionado;
  bool _cargando = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar vehículo'),
      content: widget.vehiculos.isEmpty
          ? const Text(
              'No tienes vehículos aprobados para asignar.\nRegistra y espera aprobación del administrador.')
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Opción para desasignar
                  RadioListTile<int?>(
                    value: null,
                    groupValue: _seleccionado,
                    title: const Text('Ninguno (desasignar)'),
                    onChanged: (v) => setState(() => _seleccionado = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ...widget.vehiculos.map(
                    (v) => RadioListTile<int?>(
                      value: v.id,
                      groupValue: _seleccionado,
                      title: Text(v.placa),
                      subtitle: Text(v.tipoLegible),
                      onChanged: (val) => setState(() => _seleccionado = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (widget.vehiculos.isNotEmpty)
          FilledButton(
            onPressed: _cargando
                ? null
                : () async {
                    setState(() => _cargando = true);
                    await widget.onSeleccionar(_seleccionado);
                    if (mounted) setState(() => _cargando = false);
                  },
            child: const Text('Confirmar'),
          ),
      ],
    );
  }
}
