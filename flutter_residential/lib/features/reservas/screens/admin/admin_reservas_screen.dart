import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/reserva_model.dart';
import '../../providers/reserva_provider.dart';
import '../../services/reserva_service.dart';

class AdminReservasScreen extends StatefulWidget {
  const AdminReservasScreen({super.key});

  @override
  State<AdminReservasScreen> createState() => _AdminReservasScreenState();
}

class _AdminReservasScreenState extends State<AdminReservasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservaProvider>().cargarAdmin(estado: 'PENDIENTE');
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Solicitudes'),
            Tab(text: 'Zonas comunes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _TabReservas(),
          _TabZonas(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 1 — RESERVAS (solicitudes)
// ═══════════════════════════════════════════════════════════════════

class _TabReservas extends StatefulWidget {
  const _TabReservas();

  @override
  State<_TabReservas> createState() => _TabReservasState();
}

class _TabReservasState extends State<_TabReservas> {
  String? _filtro = 'PENDIENTE';

  Future<void> _aplicarFiltro(String? estado) async {
    setState(() => _filtro = estado);
    await context.read<ReservaProvider>().cargarAdmin(estado: estado);
  }

  Future<void> _aprobar(ReservaModel r) async {
    try {
      await context.read<ReservaProvider>().aprobar(r.id);
      if (!mounted) return;
      _toast(ToastificationType.success, 'Reserva aprobada');
    } catch (e) {
      if (!mounted) return;
      _toast(ToastificationType.error, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _rechazar(ReservaModel r) async {
    final motivo = await _pedirMotivo();
    if (motivo == null || !mounted) return;
    try {
      await context.read<ReservaProvider>().rechazar(r.id, motivo);
      if (!mounted) return;
      _toast(ToastificationType.success, 'Reserva rechazada');
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
              decoration: const InputDecoration(hintText: 'Describe el motivo'),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                  child: const Text('Rechazar')),
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
    final p = context.watch<ReservaProvider>();
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () => context.read<ReservaProvider>().cargarAdmin(estado: _filtro),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _Chip(label: 'Pendientes', activo: _filtro == 'PENDIENTE',
                      onTap: () => _aplicarFiltro('PENDIENTE')),
                  const SizedBox(width: 6),
                  _Chip(label: 'Aprobadas', activo: _filtro == 'APROBADA',
                      onTap: () => _aplicarFiltro('APROBADA')),
                  const SizedBox(width: 6),
                  _Chip(label: 'Rechazadas', activo: _filtro == 'RECHAZADA',
                      onTap: () => _aplicarFiltro('RECHAZADA')),
                  const SizedBox(width: 6),
                  _Chip(label: 'Todas', activo: _filtro == null,
                      onTap: () => _aplicarFiltro(null)),
                ],
              ),
            ),
          ),
          if (p.loading && p.reservas.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (p.reservas.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy_outlined,
                        size: 48, color: cs.outline),
                    const SizedBox(height: 12),
                    Text('Sin reservas',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: p.reservas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ReservaTile(
                  reserva: p.reservas[i],
                  onAprobar: () => _aprobar(p.reservas[i]),
                  onRechazar: () => _rechazar(p.reservas[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 2 — ZONAS COMUNES
// ═══════════════════════════════════════════════════════════════════

class _TabZonas extends StatefulWidget {
  const _TabZonas();

  @override
  State<_TabZonas> createState() => _TabZonasState();
}

class _TabZonasState extends State<_TabZonas> {
  List<ZonaComunModel> _zonas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final zonas = await ReservaService.listarZonasAdmin();
      if (mounted) setState(() => _zonas = zonas);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrirFormulario({ZonaComunModel? zona}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ZonaFormSheet(
        zona: zona,
        onGuardado: _cargar,
      ),
    );
  }

  void _abrirExcepciones(ZonaComunModel zona) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExcepcionesSheet(zona: zona),
    );
  }

  Future<void> _toggleSuspension(ZonaComunModel zona) async {
    if (zona.suspendida) {
      try {
        await ReservaService.reactivarZona(zona.id);
        _cargar();
        _toast(ToastificationType.success, 'Zona reactivada');
      } catch (e) {
        _toast(ToastificationType.error, e.toString().replaceFirst('Exception: ', ''));
      }
    } else {
      final motivo = await _pedirMotivo(
        titulo: 'Suspender zona',
        hint: 'Motivo de la suspensión (mantenimiento, evento, etc.)',
      );
      if (motivo == null || !mounted) return;
      try {
        await ReservaService.suspenderZona(zona.id, motivo);
        _cargar();
        _toast(ToastificationType.success, 'Zona suspendida');
      } catch (e) {
        if (mounted) _toast(ToastificationType.error,
            e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<String?> _pedirMotivo({String titulo = 'Motivo', String hint = ''}) =>
      showDialog<String>(
        context: context,
        builder: (_) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: Text(titulo),
            content: TextField(
              controller: ctrl,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(hintText: hint),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                  child: const Text('Confirmar')),
            ],
          );
        },
      );

  void _toast(ToastificationType tipo, String msg) {
    if (!mounted) return;
    toastification.show(
      context: context,
      type: tipo,
      title: Text(msg),
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        if (_cargando)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: TextStyle(color: cs.error)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _cargar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
        else if (_zonas.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.place_outlined, size: 48, color: cs.outline),
                const SizedBox(height: 12),
                Text('Sin zonas configuradas',
                    style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _abrirFormulario(),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear zona'),
                ),
              ],
            ),
          )
        else
          RefreshIndicator(
            onRefresh: _cargar,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: _zonas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _ZonaTile(
                zona: _zonas[i],
                onEditar: () => _abrirFormulario(zona: _zonas[i]),
                onExcepciones: () => _abrirExcepciones(_zonas[i]),
                onToggleSuspension: () => _toggleSuspension(_zonas[i]),
              ),
            ),
          ),

        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_zonas',
            onPressed: () => _abrirFormulario(),
            icon: const Icon(Icons.add),
            label: const Text('Nueva zona'),
          ),
        ),
      ],
    );
  }
}

// ── Tile de Zona ──────────────────────────────────────────────────────────────

class _ZonaTile extends StatelessWidget {
  final ZonaComunModel zona;
  final VoidCallback onEditar;
  final VoidCallback onExcepciones;
  final VoidCallback onToggleSuspension;

  const _ZonaTile({
    required this.zona,
    required this.onEditar,
    required this.onExcepciones,
    required this.onToggleSuspension,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color borderColor;
    if (zona.suspendida) {
      borderColor = AppColors.warning;
    } else if (!zona.activa) {
      borderColor = cs.outlineVariant;
    } else {
      borderColor = AppColors.ok.withOpacity(0.4);
    }

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zona.nombre,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (zona.descripcion != null) ...[
                        const SizedBox(height: 2),
                        Text(zona.descripcion!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                ),
                // Estado badge
                _EstadoBadge(zona: zona),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                  onSelected: (v) {
                    if (v == 'editar') onEditar();
                    if (v == 'excepciones') onExcepciones();
                    if (v == 'suspension') onToggleSuspension();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'excepciones',
                      child: Row(children: [
                        Icon(Icons.event_note_outlined),
                        SizedBox(width: 8),
                        Text('Excepciones de horario'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'suspension',
                      child: Row(children: [
                        Icon(zona.suspendida
                            ? Icons.play_circle_outline
                            : Icons.pause_circle_outline,
                            color: zona.suspendida ? AppColors.ok : AppColors.warning),
                        const SizedBox(width: 8),
                        Text(zona.suspendida ? 'Reactivar' : 'Suspender',
                            style: TextStyle(
                                color: zona.suspendida
                                    ? AppColors.ok
                                    : AppColors.warning)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Suspensión
          if (zona.suspendida && zona.motivoSuspension != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        zona.motivoSuspension!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Detalles: aforo, horario, días
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoChip(
                  icon: Icons.people_outline,
                  label: 'Aforo: ${zona.capacidad}',
                ),
                if (zona.horaAperturaCorta != null && zona.horaCierreCorta != null)
                  _InfoChip(
                    icon: Icons.access_time_outlined,
                    label: '${zona.horaAperturaCorta} – ${zona.horaCierreCorta}',
                  ),
                if (zona.listaDias.isNotEmpty)
                  _InfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: zona.listaDias
                        .map((d) => d.substring(0, 3))
                        .join(', '),
                  ),
                if (zona.duracionMinMinutos != null || zona.duracionMaxMinutos != null)
                  _InfoChip(
                    icon: Icons.timelapse_outlined,
                    label: _duracionTexto(zona),
                  ),
                if (!zona.requiereAprobacion)
                  _InfoChip(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Auto-aprobación',
                    color: AppColors.teal,
                    bgColor: AppColors.bgTeal,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _duracionTexto(ZonaComunModel z) {
    if (z.duracionMinMinutos != null && z.duracionMaxMinutos != null) {
      return '${z.duracionMinMinutos}–${z.duracionMaxMinutos} min';
    }
    if (z.duracionMinMinutos != null) return 'Mín ${z.duracionMinMinutos} min';
    return 'Máx ${z.duracionMaxMinutos} min';
  }
}

class _EstadoBadge extends StatelessWidget {
  final ZonaComunModel zona;
  const _EstadoBadge({required this.zona});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    String label;

    if (zona.suspendida) {
      color = AppColors.warning;
      bg = AppColors.warningSoft;
      label = 'Suspendida';
    } else if (!zona.activa) {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
      bg = Theme.of(context).colorScheme.surfaceContainerHighest;
      label = 'Inactiva';
    } else {
      color = AppColors.ok;
      bg = AppColors.bgGreen;
      label = 'Activa';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Color? bgColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = color ?? cs.onSurfaceVariant;
    final bg = bgColor ?? cs.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: fg)),
        ],
      ),
    );
  }
}

// ── Bottom sheet: formulario de zona ─────────────────────────────────────────

class _ZonaFormSheet extends StatefulWidget {
  final ZonaComunModel? zona;
  final VoidCallback onGuardado;

  const _ZonaFormSheet({this.zona, required this.onGuardado});

  @override
  State<_ZonaFormSheet> createState() => _ZonaFormSheetState();
}

class _ZonaFormSheetState extends State<_ZonaFormSheet> {
  final _form = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _capacidadCtrl = TextEditingController();

  TimeOfDay? _apertura;
  TimeOfDay? _cierre;
  final Set<String> _dias = {};

  int? _durMin;
  int? _durMax;
  int? _antMin;
  int? _antMax;
  bool _requiereAprobacion = true;
  bool _activa = true;
  bool _guardando = false;

  static const _todosLosDias = [
    'LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO'
  ];
  static const _etiquetaDia = {
    'LUNES': 'Lun', 'MARTES': 'Mar', 'MIERCOLES': 'Mié',
    'JUEVES': 'Jue', 'VIERNES': 'Vie', 'SABADO': 'Sáb', 'DOMINGO': 'Dom',
  };

  @override
  void initState() {
    super.initState();
    final z = widget.zona;
    if (z != null) {
      _nombreCtrl.text = z.nombre;
      _descCtrl.text = z.descripcion ?? '';
      _capacidadCtrl.text = z.capacidad.toString();
      _activa = z.activa;
      _requiereAprobacion = z.requiereAprobacion;
      _durMin = z.duracionMinMinutos;
      _durMax = z.duracionMaxMinutos;
      _antMin = z.anticipacionMinDias;
      _antMax = z.anticipacionMaxDias;
      _dias.addAll(z.listaDias);
      if (z.horaAperturaCorta != null) {
        final p = z.horaAperturaCorta!.split(':');
        _apertura = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
      if (z.horaCierreCorta != null) {
        final p = z.horaCierreCorta!.split(':');
        _cierre = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _capacidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);

    String? _fmt(TimeOfDay? t) =>
        t != null ? '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00' : null;

    final data = <String, dynamic>{
      'nombre': _nombreCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'capacidad': int.tryParse(_capacidadCtrl.text) ?? 0,
      'activa': _activa,
      'horaApertura': _fmt(_apertura),
      'horaCierre': _fmt(_cierre),
      'diasDisponibles': _dias.isEmpty ? null : _dias.join(','),
      'duracionMinMinutos': _durMin,
      'duracionMaxMinutos': _durMax,
      'anticipacionMinDias': _antMin,
      'anticipacionMaxDias': _antMax,
      'requiereAprobacion': _requiereAprobacion,
    };

    try {
      if (widget.zona == null) {
        await ReservaService.crearZona(data);
      } else {
        await ReservaService.actualizarZona(widget.zona!.id, data);
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onGuardado();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _pickTime(bool esApertura) async {
    final inicial = esApertura ? _apertura : _cierre;
    final picked = await showTimePicker(
      context: context,
      initialTime: inicial ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (esApertura) _apertura = picked;
      else _cierre = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esEdicion = widget.zona != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  esEdicion ? 'Editar zona' : 'Nueva zona',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // ── Datos básicos ───────────────────────────
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capacidadCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Aforo máximo', hintText: '0 = sin límite'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // ── Horario ─────────────────────────────────
                _SectionTitle('Horario estándar'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TimePicker(
                        label: 'Apertura',
                        time: _apertura,
                        onTap: () => _pickTime(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimePicker(
                        label: 'Cierre',
                        time: _cierre,
                        onTap: () => _pickTime(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Días disponibles ────────────────────────
                _SectionTitle('Días disponibles'),
                const SizedBox(height: 4),
                Text(
                  'Vacío = todos los días',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: _todosLosDias.map((dia) {
                    final sel = _dias.contains(dia);
                    return FilterChip(
                      label: Text(_etiquetaDia[dia] ?? dia),
                      selected: sel,
                      onSelected: (v) =>
                          setState(() => v ? _dias.add(dia) : _dias.remove(dia)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Duración ────────────────────────────────
                _SectionTitle('Duración por reserva (minutos)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _NumField(
                        label: 'Mínimo',
                        valor: _durMin,
                        onChange: (v) => setState(() => _durMin = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumField(
                        label: 'Máximo',
                        valor: _durMax,
                        onChange: (v) => setState(() => _durMax = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Anticipación ────────────────────────────
                _SectionTitle('Anticipación (días)'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _NumField(
                        label: 'Mínimo',
                        valor: _antMin,
                        onChange: (v) => setState(() => _antMin = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumField(
                        label: 'Máximo',
                        valor: _antMax,
                        onChange: (v) => setState(() => _antMax = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Opciones ────────────────────────────────
                _SectionTitle('Opciones'),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Zona activa'),
                  value: _activa,
                  onChanged: (v) => setState(() => _activa = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Requiere aprobación manual'),
                  subtitle: const Text(
                      'Si desactivado, la reserva se aprueba automáticamente'),
                  value: _requiereAprobacion,
                  onChanged: (v) => setState(() => _requiereAprobacion = v),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(esEdicion ? 'Guardar cambios' : 'Crear zona'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom sheet: excepciones de horario ──────────────────────────────────────

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
      final e = await ReservaService.listarExcepciones(widget.zona.id);
      if (mounted) setState(() => _excepciones = e);
    } catch (_) {} finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _agregar() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ExcepcionDialog(zona: widget.zona),
    );
    if (result == null || !mounted) return;
    try {
      await ReservaService.agregarExcepcion(widget.zona.id, result);
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  Future<void> _eliminar(ExcepcionZonaComunModel ex) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar excepción'),
        content: Text('¿Eliminar la excepción del ${ex.fecha}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ReservaService.eliminarExcepcion(widget.zona.id, ex.id);
      _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
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
                IconButton.filled(
                  onPressed: _agregar,
                  icon: const Icon(Icons.add),
                  tooltip: 'Agregar excepción',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : _excepciones.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_available_outlined,
                                  size: 40, color: cs.outline),
                              const SizedBox(height: 8),
                              Text('Sin excepciones configuradas',
                                  style: TextStyle(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: ctrl,
                          itemCount: _excepciones.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _ExcepcionTile(
                            excepcion: _excepciones[i],
                            onEliminar: () => _eliminar(_excepciones[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExcepcionTile extends StatelessWidget {
  final ExcepcionZonaComunModel excepcion;
  final VoidCallback onEliminar;

  const _ExcepcionTile({required this.excepcion, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final esCierre = excepcion.esCierre;
    final color = esCierre ? AppColors.danger : AppColors.teal;
    final bgColor = esCierre ? AppColors.dangerSoft : AppColors.bgTeal;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(
              esCierre ? Icons.block_outlined : Icons.schedule_outlined,
              color: color, size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  excepcion.fecha,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  esCierre
                      ? 'Cerrado'
                      : '${excepcion.horaAperturaCorta} – ${excepcion.horaCierreCorta}',
                  style: TextStyle(fontSize: 12, color: color),
                ),
                if (excepcion.motivo != null)
                  Text(
                    excepcion.motivo!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onEliminar,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}

// ── Dialog: nueva excepción ───────────────────────────────────────────────────

class _ExcepcionDialog extends StatefulWidget {
  final ZonaComunModel zona;
  const _ExcepcionDialog({required this.zona});

  @override
  State<_ExcepcionDialog> createState() => _ExcepcionDialogState();
}

class _ExcepcionDialogState extends State<_ExcepcionDialog> {
  DateTime? _fecha;
  String _tipo = 'CIERRE_ESPECIAL';
  TimeOfDay? _apertura;
  TimeOfDay? _cierre;
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _pickTime(bool esApertura) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: esApertura
          ? const TimeOfDay(hour: 8, minute: 0)
          : const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) {
      setState(() {
        if (esApertura) _apertura = picked;
        else _cierre = picked;
      });
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  void _confirmar() {
    if (_fecha == null) return;
    if (_tipo == 'APERTURA_ESPECIAL' && (_apertura == null || _cierre == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes ingresar el horario de apertura')));
      return;
    }
    final fechaStr =
        '${_fecha!.year}-${_fecha!.month.toString().padLeft(2, '0')}-${_fecha!.day.toString().padLeft(2, '0')}';
    Navigator.pop(context, {
      'fecha': fechaStr,
      'tipo': _tipo,
      'horaApertura': _apertura != null ? _formatTime(_apertura!) : null,
      'horaCierre': _cierre != null ? _formatTime(_cierre!) : null,
      'motivo': _motivoCtrl.text.trim().isEmpty ? null : _motivoCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Nueva excepción'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_fecha == null
                  ? 'Seleccionar fecha *'
                  : '${_fecha!.day}/${_fecha!.month}/${_fecha!.year}'),
              onTap: _pickFecha,
            ),
            const Divider(),

            // Tipo
            Text('Tipo',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'CIERRE_ESPECIAL',
                  icon: Icon(Icons.block_outlined),
                  label: Text('Cerrado'),
                ),
                ButtonSegment(
                  value: 'APERTURA_ESPECIAL',
                  icon: Icon(Icons.schedule_outlined),
                  label: Text('Horario especial'),
                ),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 12),

            // Horario (solo para APERTURA_ESPECIAL)
            if (_tipo == 'APERTURA_ESPECIAL') ...[
              Row(
                children: [
                  Expanded(
                    child: _TimePicker(
                      label: 'Apertura',
                      time: _apertura,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimePicker(
                      label: 'Cierre',
                      time: _cierre,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Motivo
            TextField(
              controller: _motivoCtrl,
              decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
            onPressed: _fecha == null ? null : _confirmar,
            child: const Text('Agregar')),
      ],
    );
  }
}

// ── Reserva Tile ──────────────────────────────────────────────────────────────

class _ReservaTile extends StatelessWidget {
  final ReservaModel reserva;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const _ReservaTile({
    required this.reserva,
    required this.onAprobar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _coloresEstado(reserva.estado, cs);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(6)),
                child: Text(reserva.estadoLegible,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
              ),
              Text(reserva.fecha,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          Text(reserva.zonaComunNombre,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${reserva.horaInicio.substring(0, 5)} — ${reserva.horaFin.substring(0, 5)}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          if (reserva.observaciones?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(reserva.observaciones!,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.person_outline, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(reserva.residenteNombre,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ]),
          if (reserva.esPendiente) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                    onPressed: onRechazar, child: const Text('Rechazar')),
                const SizedBox(width: 8),
                FilledButton(onPressed: onAprobar, child: const Text('Aprobar')),
              ],
            ),
          ],
          if (reserva.motivoDecision != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.info_outline, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(reserva.motivoDecision!,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  (Color, Color) _coloresEstado(String estado, ColorScheme cs) {
    switch (estado) {
      case 'APROBADA':  return (AppColors.bgGreen, AppColors.ok);
      case 'RECHAZADA': return (AppColors.dangerSoft, AppColors.danger);
      case 'CANCELADA': return (AppColors.dangerSoft, AppColors.danger);
      default:          return (AppColors.warningSoft, AppColors.warning);
    }
  }
}

// ── Widgets reutilizables ─────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ));
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimePicker({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final texto = time != null
        ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
        : 'Sin definir';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(10),
          color: cs.surface,
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_outlined, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                Text(texto,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NumField extends StatefulWidget {
  final String label;
  final int? valor;
  final ValueChanged<int?> onChange;

  const _NumField({required this.label, required this.valor, required this.onChange});

  @override
  State<_NumField> createState() => _NumFieldState();
}

class _NumFieldState extends State<_NumField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.valor?.toString() ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      decoration: InputDecoration(labelText: widget.label, hintText: 'Sin límite'),
      keyboardType: TextInputType.number,
      onChanged: (v) => widget.onChange(int.tryParse(v)),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.activo, required this.onTap});

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
        child: Text(label,
            style: TextStyle(
              color: activo ? Colors.white : cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            )),
      ),
    );
  }
}
