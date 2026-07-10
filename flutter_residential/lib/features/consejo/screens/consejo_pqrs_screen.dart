import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../pqr/models/pqr_model.dart';
import '../../pqr/providers/pqr_provider.dart';
import '../providers/consejo_provider.dart';

/// Vista de PQRs del conjunto para el Consejo Comunal.
/// Carga las PQRs desde el endpoint /api/consejo/pqrs (no el admin).
/// Reutiliza AdminPqrsScreen para las acciones de responder/cambiar estado.
class ConsejoPqrsScreen extends StatefulWidget {
  const ConsejoPqrsScreen({super.key});

  @override
  State<ConsejoPqrsScreen> createState() => _ConsejoPqrsScreenState();
}

class _ConsejoPqrsScreenState extends State<ConsejoPqrsScreen> {
  String? _filtro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargar();
    });
  }

  Future<void> _cargar() async {
    // Carga en ConsejoProvider (endpoint /api/consejo/pqrs)
    await context.read<ConsejoProvider>().cargarPqrs(estado: _filtro);
    // Sincroniza PqrProvider para que las acciones de responder/cambiarEstado funcionen
    if (mounted) {
      final pqrsConsejo = context.read<ConsejoProvider>().pqrs;
      context.read<PqrProvider>().sincronizarDesdeConsejo(pqrsConsejo);
    }
  }

  Future<void> _aplicarFiltro(String? estado) async {
    setState(() => _filtro = estado);
    await _cargar();
  }

  Future<void> _cambiarEstado(int id, String nuevoEstado, String? comentario) async {
    try {
      await context
          .read<PqrProvider>()
          .cambiarEstado(id, nuevoEstado, comentario: comentario);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: Text('Estado actualizado'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      await _cargar();
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
      await _cargar();
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

  @override
  Widget build(BuildContext context) {
    final consejo = context.watch<ConsejoProvider>();
    final cs = Theme.of(context).colorScheme;
    final pqrs = consejo.pqrs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PQRs del Conjunto'),
        actions: [
          if (consejo.pqrsPendientes > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8CC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${consejo.pqrsPendientes} radicada${consejo.pqrsPendientes == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: Column(
          children: [
            // ── Filtros ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FiltroChip(label: 'Todas', activo: _filtro == null,
                        onTap: () => _aplicarFiltro(null)),
                    const SizedBox(width: 6),
                    _FiltroChip(label: 'Radicadas', activo: _filtro == 'RADICADA',
                        onTap: () => _aplicarFiltro('RADICADA')),
                    const SizedBox(width: 6),
                    _FiltroChip(label: 'En proceso', activo: _filtro == 'EN_PROCESO',
                        onTap: () => _aplicarFiltro('EN_PROCESO')),
                    const SizedBox(width: 6),
                    _FiltroChip(label: 'Resueltas', activo: _filtro == 'RESUELTO',
                        onTap: () => _aplicarFiltro('RESUELTO')),
                    const SizedBox(width: 6),
                    _FiltroChip(label: 'Cerradas', activo: _filtro == 'CERRADO',
                        onTap: () => _aplicarFiltro('CERRADO')),
                  ],
                ),
              ),
            ),

            // ── Lista ─────────────────────────────────────
            if (consejo.error != null && pqrs.isEmpty)
              Expanded(
                child: Center(
                  child: Text(consejo.error!, style: TextStyle(color: cs.error)),
                ),
              )
            else if (consejo.loading && pqrs.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (pqrs.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: cs.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        _filtro == null ? 'No hay PQRs registradas' : 'No hay PQRs con este estado',
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
                  itemCount: pqrs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final PqrModel pqr = pqrs[i];
                    return _PqrTileConsejo(
                      pqr: pqr,
                      onTap: () async {
                        context.read<PqrProvider>().sincronizarDesdeConsejo(pqrs);
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _buildDetalleConsejo(context, pqr),
                        );
                        await _cargar();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleConsejo(BuildContext context, PqrModel pqr) {
    return _ConsejoDetalleSheet(
      pqr: pqr,
      onCambiarEstado: _cambiarEstado,
      onResponder: _responder,
    );
  }
}

// ─── Chip de filtro ───────────────────────────────────────────────────────────

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
            color: activo ? cs.onPrimary : cs.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ─── Tile simplificado ────────────────────────────────────────────────────────

class _PqrTileConsejo extends StatelessWidget {
  final PqrModel pqr;
  final VoidCallback onTap;

  const _PqrTileConsejo({required this.pqr, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                _EstadoChip(estado: pqr.estado, legible: pqr.estadoLegible),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pqr.tipoLegible,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 16, color: cs.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pqr.asunto,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline, size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  pqr.residenteNombre,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String estado;
  final String legible;

  const _EstadoChip({required this.estado, required this.legible});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colores(estado, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        legible,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  static (Color, Color) _colores(String e, ColorScheme cs) {
    switch (e) {
      case 'RADICADA':
        return (const Color(0xFFFFE8CC), const Color(0xFFB45309));
      case 'EN_PROCESO':
        return (const Color(0xFFFFF9C4), const Color(0xFF7B6000));
      case 'RESUELTO':
        return (const Color(0xFFDCFCE7), const Color(0xFF166534));
      case 'RECHAZADA':
        return (const Color(0xFFFFEBEE), const Color(0xFFC62828));
      default:
        return (cs.surfaceContainerHighest, cs.onSurfaceVariant);
    }
  }
}

// ─── Sheet de detalle (simplificado para consejero) ──────────────────────────

class _ConsejoDetalleSheet extends StatefulWidget {
  final PqrModel pqr;
  final Future<void> Function(int, String, String?) onCambiarEstado;
  final Future<void> Function(int, String) onResponder;

  const _ConsejoDetalleSheet({
    required this.pqr,
    required this.onCambiarEstado,
    required this.onResponder,
  });

  @override
  State<_ConsejoDetalleSheet> createState() => _ConsejoDetalleSheetState();
}

class _ConsejoDetalleSheetState extends State<_ConsejoDetalleSheet> {
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

  Future<void> _enviarRespuesta() async {
    final texto = _respCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => _guardando = true);
    await widget.onResponder(_pqr.id, texto);
    if (mounted) setState(() => _guardando = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.outline, borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _pqr.asunto,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          color: cs.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _EstadoChip(estado: _pqr.estado, legible: _pqr.estadoLegible),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_pqr.tipoLegible,
                              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(_pqr.residenteNombre,
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Text('Descripción',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant, letterSpacing: 0.4)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Text(_pqr.descripcion,
                          style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.5)),
                    ),
                    const SizedBox(height: 20),
                    // Cambiar estado — acciones rápidas
                    if (!_pqr.esCerrado && !_pqr.esRechazada) ...[
                      Text('Cambiar estado',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant, letterSpacing: 0.4)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: _transiciones(_pqr.estado).map((t) {
                          return GestureDetector(
                            onTap: _guardando ? null : () async {
                              setState(() => _guardando = true);
                              await widget.onCambiarEstado(_pqr.id, t['estado']!, null);
                              if (mounted) {
                                setState(() => _guardando = false);
                                Navigator.pop(context);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Color(int.parse(t['bg']!)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Color(int.parse(t['fg']!)).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                t['label']!,
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: Color(int.parse(t['fg']!)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                    ],
                    // Responder
                    Text('Respuesta al residente',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant, letterSpacing: 0.4)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _respCtrl,
                      minLines: 3, maxLines: 6,
                      enabled: !_pqr.esCerrado && !_pqr.esRechazada,
                      decoration: InputDecoration(
                        hintText: 'Escribe la respuesta...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    if (!_pqr.esCerrado && !_pqr.esRechazada) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _guardando || _respCtrl.text.trim().isEmpty
                              ? null : _enviarRespuesta,
                          icon: _guardando
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 16),
                          label: Text(_pqr.respuestaAdmin != null
                              ? 'Actualizar respuesta' : 'Enviar respuesta'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static List<Map<String, String>> _transiciones(String estado) {
    switch (estado) {
      case 'RADICADA':
        return [
          {'estado': 'EN_PROCESO', 'label': 'Tomar caso',
           'fg': '0xFFB45309', 'bg': '0xFFFFE8CC'},
          {'estado': 'RESUELTO', 'label': 'Resolver',
           'fg': '0xFF166534', 'bg': '0xFFDCFCE7'},
          {'estado': 'RECHAZADA', 'label': 'Rechazar',
           'fg': '0xFFC62828', 'bg': '0xFFFFEBEE'},
        ];
      case 'EN_PROCESO':
        return [
          {'estado': 'RESUELTO', 'label': 'Marcar resuelta',
           'fg': '0xFF166534', 'bg': '0xFFDCFCE7'},
          {'estado': 'CERRADO', 'label': 'Cerrar',
           'fg': '0xFF616161', 'bg': '0xFFE0E0E0'},
        ];
      case 'RESUELTO':
        return [
          {'estado': 'CERRADO', 'label': 'Cerrar caso',
           'fg': '0xFF616161', 'bg': '0xFFE0E0E0'},
        ];
      default:
        return [];
    }
  }
}
