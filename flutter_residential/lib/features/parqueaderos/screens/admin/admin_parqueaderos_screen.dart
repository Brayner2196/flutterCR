import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../propiedades/services/propiedad_service.dart';
import '../../models/parqueadero_model.dart';
import '../../providers/parqueadero_provider.dart';
import '../../providers/vehiculo_provider.dart';
import '../../widgets/parqueadero_card.dart';
import 'admin_config_parqueadero_screen.dart';
import 'admin_vehiculos_screen.dart';

/// Pantalla principal de parqueaderos para TENANT_ADMIN.
/// Tres tabs: Parqueaderos (privados), Vehículos, Configuración.
///
/// Árbol:
/// AdminHomeScreen → DashboardAdminScreen (QuickAccess) → AdminParqueaderosScreen
class AdminParqueaderosScreen extends StatefulWidget {
  const AdminParqueaderosScreen({super.key});

  @override
  State<AdminParqueaderosScreen> createState() => _AdminParqueaderosScreenState();
}

class _AdminParqueaderosScreenState extends State<AdminParqueaderosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ParqueaderoProvider>().cargarAdmin();
      context.read<VehiculoProvider>().cargarAdmin(soloPendientes: false);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehiculoP = context.watch<VehiculoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parqueaderos'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            const Tab(text: 'Parqueaderos'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Vehículos'),
                  if (vehiculoP.cantidadPendientes > 0) ...[
                    const SizedBox(width: 6),
                    _BadgeCount(vehiculoP.cantidadPendientes),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Configuración'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _TabParqueaderos(),
          AdminVehiculosTab(),
          AdminConfigParqueaderoTab(),
        ],
      ),
    );
  }
}

// ─── Tab Parqueaderos ─────────────────────────────────────────────────────────

class _TabParqueaderos extends StatelessWidget {
  const _TabParqueaderos();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ParqueaderoProvider>();
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => context.read<ParqueaderoProvider>().cargarAdmin(),
      child: CustomScrollView(
        slivers: [
          // ── Resumen ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  _ResumenChip(
                    label: 'Total',
                    valor: p.parqueaderos.length,
                    color: cs.primary,
                  ),
                  const SizedBox(width: 8),
                  _ResumenChip(
                    label: 'Asignados',
                    valor: p.totalAsignados,
                    color: AppColors.ok,
                  ),
                  const SizedBox(width: 8),
                  _ResumenChip(
                    label: 'Libres',
                    valor: p.totalLibres,
                    color: AppColors.warning,
                  ),
                ],
              ),
            ),
          ),

          // ── Botón crear en bulk ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FilledButton.tonal(
                onPressed: () => _mostrarBulkDialog(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 6),
                    Text('Crear parqueaderos'),
                  ],
                ),
              ),
            ),
          ),

          // ── Loading ───────────────────────────────────────────────
          if (p.loading && p.parqueaderos.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )

          // ── Vacío ─────────────────────────────────────────────────
          else if (p.parqueaderos.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_parking, size: 48, color: cs.outline),
                    const SizedBox(height: 12),
                    Text(
                      'No hay parqueaderos registrados',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Usa "Crear parqueaderos" para agregar',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            )

          // ── Lista ─────────────────────────────────────────────────
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: p.parqueaderos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final parq = p.parqueaderos[i];
                  return ParqueaderoCard(
                    parqueadero: parq,
                    onAsignarPropiedad: () => _asignarPropiedad(ctx, parq),
                    onEliminar: () => _confirmarEliminar(ctx, parq),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Bulk dialog ─────────────────────────────────────────────────────────────

  void _mostrarBulkDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BulkCrearSheet(
        onCrear: (ids) async {
          try {
            final res = await context.read<ParqueaderoProvider>().crearBulk(ids);
            if (!context.mounted) return;
            Navigator.pop(context);
            final creados = res['creados'] as int? ?? 0;
            final duplicados = res['duplicados'] as int? ?? 0;
            toastification.show(
              context: context,
              type: ToastificationType.success,
              title: Text('$creados creado${creados == 1 ? '' : 's'}'
                  '${duplicados > 0 ? ', $duplicados duplicado${duplicados == 1 ? '' : 's'}' : ''}'),
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

  // ── Asignar propiedad ────────────────────────────────────────────────────────

  void _asignarPropiedad(BuildContext context, ParqueaderoModel parq) {
    showDialog(
      context: context,
      builder: (_) => _AsignarPropiedadDialog(
        parqueadero: parq,
        onAsignar: (propiedadId) async {
          try {
            await context
                .read<ParqueaderoProvider>()
                .asignarPropiedad(parq.id, propiedadId);
            if (!context.mounted) return;
            Navigator.pop(context);
            toastification.show(
              context: context,
              type: ToastificationType.success,
              title: Text(propiedadId != null ? 'Propiedad asignada' : 'Propiedad desasignada'),
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

  // ── Confirmar eliminar ────────────────────────────────────────────────────────

  void _confirmarEliminar(BuildContext context, ParqueaderoModel parq) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar parqueadero'),
        content: Text(
          '¿Eliminar el parqueadero "${parq.identificador}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<ParqueaderoProvider>().eliminarParqueadero(parq.id);
                if (!context.mounted) return;
                toastification.show(
                  context: context,
                  type: ToastificationType.success,
                  title: const Text('Parqueadero eliminado'),
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

// ─── Sheet de creación en bulk ───────────────────────────────────────────────

class _BulkCrearSheet extends StatefulWidget {
  final Future<void> Function(List<String> identificadores) onCrear;

  const _BulkCrearSheet({required this.onCrear});

  @override
  State<_BulkCrearSheet> createState() => _BulkCrearSheetState();
}

class _BulkCrearSheetState extends State<_BulkCrearSheet> {
  final _controller = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _identificadores => _controller.text
      .split(RegExp(r'[\n,;]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Crear parqueaderos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 6),
          Text(
            'Ingresa los identificadores separados por coma, punto y coma o salto de línea.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'P-01, P-02, P-03\no uno por línea',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Text(
            '${_identificadores.length} identificador${_identificadores.length == 1 ? '' : 'es'}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _identificadores.isEmpty || _cargando
                  ? null
                  : () async {
                      setState(() => _cargando = true);
                      await widget.onCrear(_identificadores);
                      if (mounted) setState(() => _cargando = false);
                    },
              child: _cargando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog asignar propiedad ────────────────────────────────────────────────

class _AsignarPropiedadDialog extends StatefulWidget {
  final ParqueaderoModel parqueadero;
  final Future<void> Function(int? propiedadId) onAsignar;

  const _AsignarPropiedadDialog({
    required this.parqueadero,
    required this.onAsignar,
  });

  @override
  State<_AsignarPropiedadDialog> createState() => _AsignarPropiedadDialogState();
}

class _AsignarPropiedadDialogState extends State<_AsignarPropiedadDialog> {
  final _busquedaCtrl = TextEditingController();

  List<Map<String, dynamic>> _propiedades = [];
  List<Map<String, dynamic>> _filtradas   = [];
  Map<String, dynamic>?      _seleccionada;
  bool _cargando       = false;
  bool _cargandoLista  = true;
  String? _errorLista;

  @override
  void initState() {
    super.initState();
    _cargarPropiedades();
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPropiedades() async {
    try {
      final lista = await PropiedadService.listarPropiedades();
      if (!mounted) return;
      setState(() {
        _propiedades    = lista;
        _filtradas      = lista;
        _cargandoLista  = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorLista    = e.toString().replaceFirst('Exception: ', '');
        _cargandoLista = false;
      });
    }
  }

  void _filtrar(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtradas = q.isEmpty
          ? _propiedades
          : _propiedades.where((p) {
              final path = (p['path'] as String? ?? '').toLowerCase();
              final id   = p['id'].toString();
              return path.contains(q) || id.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Asignar propiedad'),
          Text(
            'Parqueadero: ${widget.parqueadero.identificador}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant,
                fontWeight: FontWeight.normal),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Buscador
            TextField(
              controller: _busquedaCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o path…',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: _filtrar,
            ),
            const SizedBox(height: 8),

            // Lista
            if (_cargandoLista)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorLista != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_errorLista!,
                    style: TextStyle(color: cs.error, fontSize: 13)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: _filtradas.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('Sin resultados',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filtradas.length,
                        itemBuilder: (_, i) {
                          final p = _filtradas[i];
                          final seleccionado = _seleccionada?['id'] == p['id'];
                          return InkWell(
                            onTap: () => setState(() =>
                                _seleccionada = seleccionado ? null : p),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: seleccionado
                                    ? cs.primary.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: seleccionado
                                      ? cs.primary.withValues(alpha: 0.5)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    seleccionado
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                    color: seleccionado
                                        ? cs.primary
                                        : cs.outlineVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p['path'] as String? ??
                                          'Propiedad #${p['id']}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: seleccionado
                                            ? cs.primary
                                            : cs.onSurface,
                                        fontWeight: seleccionado
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (widget.parqueadero.tienePropiedad)
          TextButton(
            onPressed: _cargando
                ? null
                : () async {
                    setState(() => _cargando = true);
                    await widget.onAsignar(null);
                    if (mounted) setState(() => _cargando = false);
                  },
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('Desasignar'),
          ),
        FilledButton(
          onPressed: _cargando || _seleccionada == null
              ? null
              : () async {
                  setState(() => _cargando = true);
                  await widget.onAsignar(_seleccionada!['id'] as int);
                  if (mounted) setState(() => _cargando = false);
                },
          child: _cargando
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      color: Colors.white))
              : const Text('Asignar'),
        ),
      ],
    );
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _ResumenChip extends StatelessWidget {
  final String label;
  final int valor;
  final Color color;

  const _ResumenChip({
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$valor ',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: color,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCount extends StatelessWidget {
  final int count;

  const _BadgeCount(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
