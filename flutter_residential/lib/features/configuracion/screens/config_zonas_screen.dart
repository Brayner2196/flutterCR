import 'package:flutter/material.dart';
import 'package:flutter_residential/features/configuracion/widgets/zona_form_sheet.dart';
import 'package:flutter_residential/features/reservas/models/reserva_model.dart';
import 'package:flutter_residential/features/reservas/services/reserva_service.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

class ConfigZonasScreen extends StatefulWidget {
  const ConfigZonasScreen({super.key});

  @override
  State<ConfigZonasScreen> createState() => _ConfigZonasScreenState();
}

class _ConfigZonasScreenState extends State<ConfigZonasScreen> {
  List<ZonaComunModel> _zonas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      _zonas = await ReservaService.listarZonasAdmin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _abrirFormulario({ZonaComunModel? zona}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ZonaFormSheet(zona: zona, onGuardado: _cargar),
    );
  }

  Future<void> _suspender(ZonaComunModel zona) async {
    String? motivo;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Suspender zona'),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(
              labelText: 'Motivo de suspensión',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (v) => motivo = v,
            maxLines: 2,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Suspender'),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    try {
      await ReservaService.suspenderZona(zona.id, motivo ?? '');
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  Future<void> _reactivar(ZonaComunModel zona) async {
    try {
      await ReservaService.reactivarZona(zona.id);
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  void _verExcepciones(ZonaComunModel zona) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ExcepcionesSheet(zona: zona),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonas comunes'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva zona'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _zonas.isEmpty
              ? _EmptyView(onCrear: () => _abrirFormulario())
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _zonas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ZonaTile(
                      zona: _zonas[i],
                      onEditar: () => _abrirFormulario(zona: _zonas[i]),
                      onSuspender: () => _suspender(_zonas[i]),
                      onReactivar: () => _reactivar(_zonas[i]),
                      onExcepciones: () => _verExcepciones(_zonas[i]),
                    ),
                  ),
                ),
    );
  }
}

// ── Tile de zona ──────────────────────────────────────────────────────────────

class _ZonaTile extends StatelessWidget {
  final ZonaComunModel zona;
  final VoidCallback onEditar;
  final VoidCallback onSuspender;
  final VoidCallback onReactivar;
  final VoidCallback onExcepciones;

  const _ZonaTile({
    required this.zona,
    required this.onEditar,
    required this.onSuspender,
    required this.onReactivar,
    required this.onExcepciones,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    Color estadoColor;
    String estadoLabel;
    IconData estadoIcon;

    if (zona.suspendida) {
      estadoColor = Colors.orange;
      estadoLabel = 'Suspendida';
      estadoIcon = Icons.pause_circle_outline;
    } else if (zona.activa) {
      estadoColor = AppColors.ok;
      estadoLabel = 'Activa';
      estadoIcon = Icons.check_circle_outline;
    } else {
      estadoColor = cs.error;
      estadoLabel = 'Inactiva';
      estadoIcon = Icons.cancel_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: estadoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.pool_outlined, color: estadoColor, size: 22),
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(zona.nombre,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcon, size: 11, color: estadoColor),
                      const SizedBox(width: 3),
                      Text(estadoLabel,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: estadoColor)),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (zona.descripcion != null)
                  Text(zona.descripcion!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    if (zona.capacidad > 0)
                      _Chip(Icons.group_outlined, '${zona.capacidad} personas'),
                    if (zona.horaAperturaCorta != null && zona.horaCierreCorta != null)
                      _Chip(Icons.schedule_outlined,
                          '${zona.horaAperturaCorta} - ${zona.horaCierreCorta}'),
                    if (zona.requiereAprobacion)
                      _Chip(Icons.verified_outlined, 'Aprobación requerida'),
                    if (zona.motivoSuspension != null)
                      _Chip(Icons.warning_amber_outlined,
                          zona.motivoSuspension!, color: Colors.orange),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (v) {
                if (v == 'editar') onEditar();
                if (v == 'suspender') onSuspender();
                if (v == 'reactivar') onReactivar();
                if (v == 'excepciones') onExcepciones();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'editar',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Editar zona')
                    ])),
                const PopupMenuItem(
                    value: 'excepciones',
                    child: Row(children: [
                      Icon(Icons.event_busy_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Excepciones de horario')
                    ])),
                if (!zona.suspendida && zona.activa)
                  const PopupMenuItem(
                    value: 'suspender',
                    child: Row(children: [
                      Icon(Icons.pause_circle_outline,
                          size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Suspender',
                          style: TextStyle(color: Colors.orange)),
                    ]),
                  ),
                if (zona.suspendida)
                  PopupMenuItem(
                    value: 'reactivar',
                    child: Row(children: [
                      Icon(Icons.play_circle_outline,
                          size: 16, color: AppColors.ok),
                      const SizedBox(width: 8),
                      Text('Reactivar',
                          style: TextStyle(color: AppColors.ok)),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip de info ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Chip(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: c)),
      ],
    );
  }
}

// ── Sheet de excepciones ──────────────────────────────────────────────────────

class _ExcepcionesSheet extends StatefulWidget {
  final ZonaComunModel zona;
  const _ExcepcionesSheet({required this.zona});

  @override
  State<_ExcepcionesSheet> createState() => _ExcepcionesSheetState();
}

class _ExcepcionesSheetState extends State<_ExcepcionesSheet> {
  List<ExcepcionZonaComunModel> _excepciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      _excepciones = await ReservaService.listarExcepciones(widget.zona.id);
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _agregar() async {
    DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha == null || !mounted) return;

    String tipo = 'CIERRE_ESPECIAL';
    String? motivo;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        final mCtrl = TextEditingController();
        String tipoLocal = tipo;
        return StatefulBuilder(
          builder: (_, setDlg) => AlertDialog(
            title: Text('Excepción: ${fecha.day}/${fecha.month}/${fecha.year}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'CIERRE_ESPECIAL', label: Text('Cierre')),
                    ButtonSegment(value: 'APERTURA_ESPECIAL', label: Text('Apertura especial')),
                  ],
                  selected: {tipoLocal},
                  onSelectionChanged: (s) => setDlg(() => tipoLocal = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: mCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Motivo (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => motivo = v,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () {
                    tipo = tipoLocal;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Agregar')),
            ],
          ),
        );
      },
    );

    if (ok != true || !mounted) return;
    try {
      await ReservaService.agregarExcepcion(widget.zona.id, {
        'fecha': '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
        'tipo': tipo,
        if (motivo != null && motivo!.isNotEmpty) 'motivo': motivo,
      });
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  Future<void> _eliminar(ExcepcionZonaComunModel exc) async {
    try {
      await ReservaService.eliminarExcepcion(widget.zona.id, exc.id);
      await _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Excepciones de horario',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(widget.zona.nombre,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _agregar,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_cargando)
            const Center(child: CircularProgressIndicator())
          else if (_excepciones.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Sin excepciones registradas',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _excepciones.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final exc = _excepciones[i];
                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                    leading: Icon(
                      exc.esCierre
                          ? Icons.event_busy_outlined
                          : Icons.event_available_outlined,
                      color: exc.esCierre ? Colors.red : Colors.green,
                    ),
                    title: Text(exc.fecha,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      exc.esCierre ? 'Cierre especial${exc.motivo != null ? ' · ${exc.motivo}' : ''}' : 'Apertura especial',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      onPressed: () => _eliminar(exc),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty view ────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onCrear;
  const _EmptyView({required this.onCrear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pool_outlined, size: 56, color: cs.outlineVariant),
            const SizedBox(height: 16),
            const Text('Sin zonas comunes',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Crea la primera zona para que los residentes puedan hacer reservas',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCrear,
              icon: const Icon(Icons.add),
              label: const Text('Crear zona'),
            ),
          ],
        ),
      ),
    );
  }
}
