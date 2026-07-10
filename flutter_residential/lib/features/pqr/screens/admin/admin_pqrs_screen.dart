import 'package:flutter/material.dart';
import 'package:flutter_residential/core/utils/date_formatter.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../models/pqr_model.dart';
import '../../providers/pqr_provider.dart';
import '../../../home/admin/widgets/dashboard/dashboard_tokens.dart';

class AdminPqrsScreen extends StatefulWidget {
  const AdminPqrsScreen({super.key});

  @override
  State<AdminPqrsScreen> createState() => _AdminPqrsScreenState();
}

class _AdminPqrsScreenState extends State<AdminPqrsScreen> {
  String? _filtro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PqrProvider>().cargarAdmin(estado: _filtro);
    });
  }

  Future<void> _aplicarFiltro(String? estado) async {
    setState(() => _filtro = estado);
    await context.read<PqrProvider>().cargarAdmin(estado: estado);
  }

  Future<void> _abrirDetalle(PqrModel pqr) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PqrDetalleSheet(
        pqr: pqr,
        onCambiarEstado: (id, estado, comentario) =>
            _cambiarEstado(id, estado, comentario),
        onResponder: (id, respuesta) => _responder(id, respuesta),
      ),
    );
  }

  Future<void> _cambiarEstado(
      int id, String nuevoEstado, String? comentario) async {
    try {
      await context
          .read<PqrProvider>()
          .cambiarEstado(id, nuevoEstado, comentario: comentario);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: Text('Estado actualizado a ${estadoLegible(nuevoEstado)}'),
        autoCloseDuration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(e.toString().replaceFirst('Exception: ', '')),
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _responder(int id, String respuesta) async {
    try {
      await context.read<PqrProvider>().responder(id, respuesta);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Respuesta enviada al residente'),
        autoCloseDuration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(e.toString().replaceFirst('Exception: ', '')),
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  static String estadoLegible(String e) {
    const map = {
      'RADICADA': 'Radicada',
      'EN_PROCESO': 'En proceso',
      'RESUELTO': 'Resuelta',
      'CERRADO': 'Cerrada',
      'RECHAZADA': 'Rechazada',
    };
    return map[e] ?? e;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PqrProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de PQRs'),
        actions: [
          if (p.cantidadPendientes > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: DashboardTokens.bgOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${p.cantidadPendientes} radicada${p.cantidadPendientes == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: DashboardTokens.fgOrange,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<PqrProvider>().cargarAdmin(estado: _filtro),
        child: Column(
          children: [
            // ── Filtros ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FiltroChip(
                      label: 'Todas',
                      activo: _filtro == null,
                      colorActivo: DashboardTokens.fgTeal,
                      bgActivo: DashboardTokens.bgTeal,
                      onTap: () => _aplicarFiltro(null),
                    ),
                    const SizedBox(width: 6),
                    _FiltroChip(
                      label: 'Radicadas',
                      activo: _filtro == 'RADICADA',
                      colorActivo: DashboardTokens.fgPurple,
                      bgActivo: DashboardTokens.bgPurple,
                      onTap: () => _aplicarFiltro('RADICADA'),
                    ),
                    const SizedBox(width: 6),
                    _FiltroChip(
                      label: 'Cerradas',
                      activo: _filtro == 'CERRADO',
                      colorActivo: cs.onSurfaceVariant,
                      bgActivo: cs.surfaceContainerHighest,
                      onTap: () => _aplicarFiltro('CERRADO'),
                    ),
                    const SizedBox(width: 6),
                    _FiltroChip(
                      label: 'En proceso',
                      activo: _filtro == 'EN_PROCESO',
                      colorActivo: DashboardTokens.fgYellow,
                      bgActivo: DashboardTokens.bgYellow,
                      onTap: () => _aplicarFiltro('EN_PROCESO'),
                    ),
                    const SizedBox(width: 6),
                    _FiltroChip(
                      label: 'Resueltas',
                      activo: _filtro == 'RESUELTO',
                      colorActivo: DashboardTokens.fgGreen,
                      bgActivo: DashboardTokens.bgGreen,
                      onTap: () => _aplicarFiltro('RESUELTO'),
                    ),
                    
                    const SizedBox(width: 6),
                    _FiltroChip(
                      label: 'Rechazadas',
                      activo: _filtro == 'RECHAZADA',
                      colorActivo: cs.error,
                      bgActivo: cs.errorContainer,
                      onTap: () => _aplicarFiltro('RECHAZADA'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Lista ─────────────────────────────────────
            if (p.error != null && p.pqrs.isEmpty)
              Expanded(
                child: Center(
                  child: Text(p.error!, style: TextStyle(color: cs.error)),
                ),
              )
            else if (p.loading && p.pqrs.isEmpty)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (p.pqrs.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 48, color: cs.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        _filtro == null
                            ? 'No hay PQRs registradas'
                            : 'No hay PQRs con este estado',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: p.pqrs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PqrTile(
                    pqr: p.pqrs[i],
                    onTap: () => _abrirDetalle(p.pqrs[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Chip de filtro ───────────────────────────────────────────────────────────

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  final Color? colorActivo;
  final Color? bgActivo;

  const _FiltroChip({
    required this.label,
    required this.activo,
    required this.onTap,
    this.colorActivo,
    this.bgActivo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = activo ? (colorActivo ?? cs.onPrimary) : cs.onSurface;
    final bg = activo ? (bgActivo ?? cs.primary) : cs.surface;
    final border = activo ? (colorActivo ?? cs.primary) : cs.outline;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Tile de PQR ─────────────────────────────────────────────────────────────

class _PqrTile extends StatelessWidget {
  final PqrModel pqr;
  final VoidCallback onTap;

  const _PqrTile({required this.pqr, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _coloresEstado(pqr.estado, cs);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pqr.estadoLegible,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: fg),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pqr.tipoLegible,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ),
                const Spacer(),
                if (pqr.respuestaAdmin != null)
                  Icon(Icons.reply_outlined,
                      size: 16, color: DashboardTokens.fgGreen),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pqr.asunto,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              pqr.descripcion,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(pqr.residenteNombre,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
                const SizedBox(width: 8),
                Text('·', style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(width: 8),
                Icon(Icons.home_filled,
                    size: 13, color: cs.onSurfaceVariant),
                
                const SizedBox(width: 4),
                Text(
                    pqr.propiedadIdentificador ??
                        (pqr.propiedadId?.toString() ?? 'N/A'),
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
                if (pqr.creadoEn != null) ...[
                  const SizedBox(width: 8),
                  Text('·', style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  Icon(Icons.schedule_outlined,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.fechaHoraMinAmPm(pqr.creadoEn!),
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
                const Spacer(),
                Icon(Icons.chevron_right,
                    size: 16, color: cs.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static (Color, Color) _coloresEstado(String estado, ColorScheme cs) {
    switch (estado) {
      case 'RADICADA':
        return (DashboardTokens.bgOrange, DashboardTokens.fgOrange);
      case 'EN_PROCESO':
        return (DashboardTokens.bgYellow, DashboardTokens.fgYellow);
      case 'RESUELTO':
        return (DashboardTokens.bgGreen, DashboardTokens.fgGreen);
      case 'RECHAZADA':
        return (
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
        );
      default:
        return (cs.surfaceContainerHighest, cs.onSurfaceVariant);
    }
  }
}

// ─── Sheet de detalle / gestión completa ─────────────────────────────────────

class _PqrDetalleSheet extends StatefulWidget {
  final PqrModel pqr;
  final Future<void> Function(int id, String estado, String? comentario)
      onCambiarEstado;
  final Future<void> Function(int id, String respuesta) onResponder;

  const _PqrDetalleSheet({
    required this.pqr,
    required this.onCambiarEstado,
    required this.onResponder,
  });

  @override
  State<_PqrDetalleSheet> createState() => _PqrDetalleSheetState();
}

class _PqrDetalleSheetState extends State<_PqrDetalleSheet> {
  late final TextEditingController _respCtrl;
  bool _guardando = false;
  late PqrModel _pqr;

  @override
  void initState() {
    super.initState();
    _pqr = widget.pqr;
    _respCtrl = TextEditingController(text: widget.pqr.respuestaAdmin ?? '');
  }

  @override
  void dispose() {
    _respCtrl.dispose();
    super.dispose();
  }

  /// Muestra el diálogo de selección de estado + comentario opcional.
  Future<void> _abrirDialogoCambiarEstado() async {
    final transiciones = _transicionesDisponibles(_pqr.estado);
    if (transiciones.isEmpty) return;

    String? estadoSeleccionado = transiciones.first.estado;
    final comentCtrl = TextEditingController();

    final resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('Cambiar estado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecciona el nuevo estado:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                // Chips de estados disponibles
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: transiciones.map((t) {
                    final seleccionado = estadoSeleccionado == t.estado;
                    return GestureDetector(
                      onTap: () =>
                          setStateDialog(() => estadoSeleccionado = t.estado),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: seleccionado ? t.bgColor : t.bgColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: seleccionado
                                ? t.color
                                : t.color.withValues(alpha: 0.3),
                            width: seleccionado ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, size: 15, color: t.color),
                            const SizedBox(width: 6),
                            Text(
                              t.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: seleccionado
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: t.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: comentCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Comentario (opcional)',
                    hintText: 'Ej: Iniciando investigación...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: estadoSeleccionado == null
                    ? null
                    : () => Navigator.pop(ctx, true),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );

    if (resultado != true || estadoSeleccionado == null) return;
    final comentario = comentCtrl.text.trim();

    setState(() => _guardando = true);
    await widget.onCambiarEstado(
        _pqr.id, estadoSeleccionado!, comentario.isEmpty ? null : comentario);

    if (mounted) {
      final pqrActualizada = context
          .read<PqrProvider>()
          .pqrs
          .firstWhere((p) => p.id == _pqr.id, orElse: () => _pqr);
      setState(() {
        _pqr = pqrActualizada;
        _guardando = false;
      });
    }
  }

  Future<void> _enviarRespuesta() async {
    final texto = _respCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => _guardando = true);
    await widget.onResponder(_pqr.id, texto);
    if (mounted) {
      final pqrActualizada = context
          .read<PqrProvider>()
          .pqrs
          .firstWhere((p) => p.id == _pqr.id, orElse: () => _pqr);
      setState(() {
        _pqr = pqrActualizada;
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _coloresEstado(_pqr.estado, cs);
    final transiciones = _transicionesDisponibles(_pqr.estado);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    // ── Header ────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _pqr.estadoLegible,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: fg),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _pqr.tipoLegible,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _pqr.asunto,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),

                    // ── Metadata ──────────────────────────
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _InfoChip(
                          icon: Icons.person_outline,
                          label: _pqr.residenteNombre,
                          cs: cs,
                        ),
                        if (_pqr.creadoEn != null)
                          _InfoChip(
                            icon: Icons.calendar_today_outlined,
                            label: DateFormatter.fechaHoraMinAmPm(_pqr.creadoEn!),
                            cs: cs,
                          ),
                        if (_pqr.propiedadId != null)
                          _InfoChip(
                            icon: Icons.home_outlined,
                            label: 'Propiedad #${_pqr.propiedadId}',
                            cs: cs,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // ── Descripción completa ───────────────
                    Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Text(
                        _pqr.descripcion,
                        style: TextStyle(
                            fontSize: 14, color: cs.onSurface, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Cambio de estado ───────────────────
                    if (!_pqr.esCerrado && !_pqr.esRechazada) ...[
                      Row(
                        children: [
                          Text(
                            'Cambiar estado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (transiciones.isNotEmpty) ...[
                            const Spacer(),
                            // Chips de acceso rápido
                            ...transiciones.take(2).map((t) => Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _BotonTransicionRapida(
                                    transicion: t,
                                    guardando: _guardando,
                                    onTap: () async {
                                      setState(() => _guardando = true);
                                      await widget.onCambiarEstado(
                                          _pqr.id, t.estado, null);
                                      if (mounted) {
                                        final actualizada = context
                                            .read<PqrProvider>()
                                            .pqrs
                                            .firstWhere((p) => p.id == _pqr.id,
                                                orElse: () => _pqr);
                                        setState(() {
                                          _pqr = actualizada;
                                          _guardando = false;
                                        });
                                      }
                                    },
                                  ),
                                )),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Botón de cambio manual con diálogo
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _guardando ? null : _abrirDialogoCambiarEstado,
                          icon: _guardando
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: const Text('Cambio manual con comentario'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                    ],

                    // ── Respuesta al residente ─────────────
                    Row(
                      children: [
                        Text(
                          'Respuesta al residente',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.4,
                          ),
                        ),
                        if (_pqr.respuestaAdmin != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: DashboardTokens.bgGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Respondida',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: DashboardTokens.fgGreen),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_pqr.fechaRespuesta != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Respondida el ${ DateFormatter.fechaHoraMinAmPm(_pqr.fechaRespuesta)}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ),

                    TextField(
                      controller: _respCtrl,
                      minLines: 3,
                      maxLines: 8,
                      enabled: !_pqr.esCerrado && !_pqr.esRechazada,
                      decoration: InputDecoration(
                        hintText: (_pqr.esCerrado || _pqr.esRechazada)
                            ? 'PQR finalizada — no se puede editar'
                            : 'Escribe la respuesta para el residente...',
                        filled: true,
                        fillColor: (_pqr.esCerrado || _pqr.esRechazada)
                            ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    if (!_pqr.esCerrado && !_pqr.esRechazada) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _guardando || _respCtrl.text.trim().isEmpty
                              ? null
                              : _enviarRespuesta,
                          icon: _guardando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 16),
                          label: Text(_pqr.respuestaAdmin != null
                              ? 'Actualizar respuesta'
                              : 'Enviar respuesta'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static (Color, Color) _coloresEstado(String estado, ColorScheme cs) {
    switch (estado) {
      case 'RADICADA':
        return (DashboardTokens.bgOrange, DashboardTokens.fgOrange);
      case 'EN_PROCESO':
        return (DashboardTokens.bgYellow, DashboardTokens.fgYellow);
      case 'RESUELTO':
        return (DashboardTokens.bgGreen, DashboardTokens.fgGreen);
      case 'RECHAZADA':
        return (const Color(0xFFFFEBEE), const Color(0xFFC62828));
      default:
        return (const Color(0xFFE0E0E0), const Color(0xFF616161));
    }
  }

  static List<_Transicion> _transicionesDisponibles(String estado) {
    switch (estado) {
      case 'RADICADA':
        return [
          _Transicion(
            estado: 'EN_PROCESO',
            label: 'Tomar caso',
            icon: Icons.play_arrow_rounded,
            color: DashboardTokens.fgYellow,
            bgColor: DashboardTokens.bgYellow,
          ),
          _Transicion(
            estado: 'RESUELTO',
            label: 'Resolver',
            icon: Icons.check_circle_outline,
            color: DashboardTokens.fgGreen,
            bgColor: DashboardTokens.bgGreen,
          ),
          _Transicion(
            estado: 'RECHAZADA',
            label: 'Rechazar',
            icon: Icons.block_outlined,
            color: const Color(0xFFC62828),
            bgColor: const Color(0xFFFFEBEE),
          ),
        ];
      case 'EN_PROCESO':
        return [
          _Transicion(
            estado: 'RESUELTO',
            label: 'Marcar resuelta',
            icon: Icons.check_circle_outline,
            color: DashboardTokens.fgGreen,
            bgColor: DashboardTokens.bgGreen,
          ),
          _Transicion(
            estado: 'CERRADO',
            label: 'Cerrar',
            icon: Icons.lock_outline,
            color: const Color(0xFF616161),
            bgColor: const Color(0xFFE0E0E0),
          ),
          _Transicion(
            estado: 'RECHAZADA',
            label: 'Rechazar',
            icon: Icons.block_outlined,
            color: const Color(0xFFC62828),
            bgColor: const Color(0xFFFFEBEE),
          ),
        ];
      case 'RESUELTO':
        return [
          _Transicion(
            estado: 'CERRADO',
            label: 'Cerrar caso',
            icon: Icons.lock_outline,
            color: const Color(0xFF616161),
            bgColor: const Color(0xFFE0E0E0),
          ),
        ];
      default:
        return [];
    }
  }
}

// ─── Botón de transición rápida (sin diálogo) ────────────────────────────────

class _BotonTransicionRapida extends StatelessWidget {
  final _Transicion transicion;
  final bool guardando;
  final VoidCallback onTap;

  const _BotonTransicionRapida({
    required this.transicion,
    required this.guardando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: guardando ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: transicion.bgColor,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: transicion.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(transicion.icon, size: 14, color: transicion.color),
            const SizedBox(width: 4),
            Text(
              transicion.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: transicion.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Modelo de transición ─────────────────────────────────────────────────────

class _Transicion {
  final String estado;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _Transicion({
    required this.estado,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

// ─── Chip de info ─────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: cs.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    );
  }
}
