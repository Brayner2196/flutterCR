import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../../models/pqr_model.dart';
import '../../../../../providers/pqr_provider.dart';
import '../../widgets/dashboard/dashboard_tokens.dart';

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
        onCambiarEstado: (id, estado) => _cambiarEstado(id, estado),
        onResponder: (id, respuesta) => _responder(id, respuesta),
      ),
    );
  }

  Future<void> _cambiarEstado(int id, String nuevoEstado) async {
    try {
      await context.read<PqrProvider>().cambiarEstado(id, nuevoEstado);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: Text('Estado actualizado a ${_estadoLegible(nuevoEstado)}'),
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

  static String _estadoLegible(String e) {
    const map = {
      'PENDIENTE': 'Pendiente',
      'EN_PROCESO': 'En proceso',
      'RESUELTO': 'Resuelto',
      'CERRADO': 'Cerrado',
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
                    '${p.cantidadPendientes} pendiente${p.cantidadPendientes == 1 ? '' : 's'}',
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
                      onTap: () => _aplicarFiltro(null),
                    ),
                    const SizedBox(width: 6),
                    _FiltroChip(
                      label: 'Pendientes',
                      activo: _filtro == 'PENDIENTE',
                      colorActivo: DashboardTokens.fgOrange,
                      bgActivo: DashboardTokens.bgOrange,
                      onTap: () => _aplicarFiltro('PENDIENTE'),
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
                      label: 'Cerradas',
                      activo: _filtro == 'CERRADO',
                      colorActivo: cs.onSurfaceVariant,
                      bgActivo: cs.surfaceContainerHighest,
                      onTap: () => _aplicarFiltro('CERRADO'),
                    ),
                  ],
                ),
              ),
            ),

            // ── Lista ─────────────────────────────────────
            if (p.error != null && p.pqrs.isEmpty)
              Expanded(
                child: Center(
                  child: Text(p.error!,
                      style: TextStyle(color: cs.error)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                // Badge estado
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
                // Badge tipo
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
                // Indicador de respuesta
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
              style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
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
                if (pqr.creadoEn != null) ...[
                  const SizedBox(width: 8),
                  Text('·',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  Icon(Icons.schedule_outlined,
                      size: 13, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _formatFecha(pqr.creadoEn!),
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
      case 'PENDIENTE':
        return (DashboardTokens.bgOrange, DashboardTokens.fgOrange);
      case 'EN_PROCESO':
        return (DashboardTokens.bgYellow, DashboardTokens.fgYellow);
      case 'RESUELTO':
        return (DashboardTokens.bgGreen, DashboardTokens.fgGreen);
      default:
        return (cs.surfaceContainerHighest, cs.onSurfaceVariant);
    }
  }

  static String _formatFecha(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Sheet de detalle / gestión completa ─────────────────────────────────────

class _PqrDetalleSheet extends StatefulWidget {
  final PqrModel pqr;
  final Future<void> Function(int id, String estado) onCambiarEstado;
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
  // Copia local del PQR para reflejar cambios sin cerrar el sheet
  late PqrModel _pqr;

  @override
  void initState() {
    super.initState();
    _pqr = widget.pqr;
    _respCtrl =
        TextEditingController(text: widget.pqr.respuestaAdmin ?? '');
  }

  @override
  void dispose() {
    _respCtrl.dispose();
    super.dispose();
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    setState(() => _guardando = true);
    await widget.onCambiarEstado(_pqr.id, nuevoEstado);
    // Refrescar la copia local desde el provider
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
              // Handle
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

              // Contenido scrollable
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        // Botón cerrar
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
                            label: _formatFecha(_pqr.creadoEn!),
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
                        color: cs.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Text(
                        _pqr.descripcion,
                        style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurface,
                            height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Cambio de estado ───────────────────
                    if (!_pqr.esCerrado) ...[
                      Text(
                        'Cambiar estado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _BotonesEstado(
                        estadoActual: _pqr.estado,
                        guardando: _guardando,
                        onCambiar: _cambiarEstado,
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

                    // Mostrar fecha de respuesta anterior si existe
                    if (_pqr.fechaRespuesta != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Respondida el ${_formatFecha(_pqr.fechaRespuesta!)}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ),

                    TextField(
                      controller: _respCtrl,
                      minLines: 3,
                      maxLines: 8,
                      enabled: !_pqr.esCerrado,
                      decoration: InputDecoration(
                        hintText: _pqr.esCerrado
                            ? 'PQR cerrada — no se puede editar'
                            : 'Escribe la respuesta para el residente...',
                        filled: true,
                        fillColor: _pqr.esCerrado
                            ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    if (!_pqr.esCerrado) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _guardando ||
                                  _respCtrl.text.trim().isEmpty
                              ? null
                              : _enviarRespuesta,
                          icon: _guardando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
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
      case 'PENDIENTE':
        return (DashboardTokens.bgOrange, DashboardTokens.fgOrange);
      case 'EN_PROCESO':
        return (DashboardTokens.bgYellow, DashboardTokens.fgYellow);
      case 'RESUELTO':
        return (DashboardTokens.bgGreen, DashboardTokens.fgGreen);
      default:
        return (
          const Color(0xFFE0E0E0),
          const Color(0xFF616161),
        );
    }
  }

  static String _formatFecha(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

// ─── Botones de transición de estado ─────────────────────────────────────────

class _BotonesEstado extends StatelessWidget {
  final String estadoActual;
  final bool guardando;
  final Future<void> Function(String) onCambiar;

  const _BotonesEstado({
    required this.estadoActual,
    required this.guardando,
    required this.onCambiar,
  });

  @override
  Widget build(BuildContext context) {
    // Transiciones válidas por estado
    final transiciones = _transicionesDisponibles(estadoActual);
    if (transiciones.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: transiciones
          .map((t) => _BotonTransicion(
                transicion: t,
                guardando: guardando,
                onTap: () => onCambiar(t.estado),
              ))
          .toList(),
    );
  }

  static List<_Transicion> _transicionesDisponibles(String estado) {
    switch (estado) {
      case 'PENDIENTE':
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
            icon: Icons.cancel_outlined,
            color: const Color(0xFF616161),
            bgColor: const Color(0xFFE0E0E0),
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

class _BotonTransicion extends StatelessWidget {
  final _Transicion transicion;
  final bool guardando;
  final VoidCallback onTap;

  const _BotonTransicion({
    required this.transicion,
    required this.guardando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: guardando ? null : onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: transicion.bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: transicion.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(transicion.icon, size: 16, color: transicion.color),
            const SizedBox(width: 6),
            Text(
              transicion.label,
              style: TextStyle(
                fontSize: 13,
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
