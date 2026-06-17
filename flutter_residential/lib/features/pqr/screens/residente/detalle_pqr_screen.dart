import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../models/pqr_historial_model.dart';
import '../../models/pqr_model.dart';
import '../../services/pqr_service.dart';
import '../../../../shared/widgets/estado_badge.dart';
import '../../../home/admin/widgets/dashboard/dashboard_tokens.dart';

class DetallePqrScreen extends StatefulWidget {
  final PqrModel pqr;

  const DetallePqrScreen({super.key, required this.pqr});

  @override
  State<DetallePqrScreen> createState() => _DetallePqrScreenState();
}

class _DetallePqrScreenState extends State<DetallePqrScreen> {
  List<PqrHistorialModel>? _historial;
  bool _loading = true;
  String? _error;

  bool get _tieneRespuesta =>
      widget.pqr.respuestaAdmin != null &&
      widget.pqr.respuestaAdmin!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await PqrService.historialPqr(widget.pqr.id);
      if (mounted) setState(() { _historial = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pqr = widget.pqr;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de PQR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _cargarHistorial,
          ),
        ],
      ),

      // ─── Panel de respuesta al fondo ────────────────────────────────────────
      bottomNavigationBar: _tieneRespuesta
          ? _RespuestaAdminPanel(pqr: pqr)
          : null,

      body: SingleChildScrollView(
        // Padding extra abajo cuando hay panel para que el contenido no quede tapado
        padding: EdgeInsets.fromLTRB(20, 20, 20, _tieneRespuesta ? 8 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Badges ──────────────────────────
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EstadoBadge(estado: pqr.estado, label: pqr.estadoLegible),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      pqr.tipoLegible,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Asunto ──────────────────────────
            Text(
              pqr.asunto,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // ─── Descripción ─────────────────────
            Text(
              'Descripción',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(pqr.descripcion, style: const TextStyle(fontSize: 14)),
            
            // ─── Timeline de trazabilidad ────────
            const Divider(height: 32),
            Text(
              'Trazabilidad',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'No se pudo cargar el historial',
                  style: TextStyle(fontSize: 12, color: cs.error),
                ),
              )
            else if (!_loading && (_historial == null || _historial!.isEmpty))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Sin movimientos registrados',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              )
            else
              Skeletonizer(
                enabled: _loading,
                child: Column(
                  children: _loading
                      ? List.generate(3, (i) => _TimelineEntry(
                          entry: PqrHistorialModel.skeleton(),
                          esUltimo: i == 2,
                        ))
                      : List.generate(_historial!.length, (i) {
                          final entry = _historial![i];
                          final esUltimo = i == _historial!.length - 1;
                          return _TimelineEntry(entry: entry, esUltimo: esUltimo);
                        }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Panel fijo de respuesta de la administración ────────────────────────────

class _RespuestaAdminPanel extends StatelessWidget {
  final PqrModel pqr;

  const _RespuestaAdminPanel({required this.pqr});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottomPadding),
      decoration: BoxDecoration(
        color: DashboardTokens.bgGreen,
        border: Border(
          top: BorderSide(
            color: DashboardTokens.fgGreen.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header con badge ───────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: DashboardTokens.fgGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: DashboardTokens.fgGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Respondida',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: DashboardTokens.fgGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Respuesta de la administración',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DashboardTokens.fgGreen,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ─── Texto de la respuesta ──────────────
          Text(
            pqr.respuestaAdmin!,
            style: TextStyle(fontSize: 13, color: Colors.black87),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // ─── Fecha ─────────────────────────────
          if (pqr.fechaRespuesta != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 12,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.fechaHora12(pqr.fechaRespuesta),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Timeline entry ───────────────────────────────────────────────────────────

class _TimelineEntry extends StatelessWidget {
  final PqrHistorialModel entry;
  final bool esUltimo;

  const _TimelineEntry({required this.entry, required this.esUltimo});

  Color _dotColor(BuildContext context, String estado) {
    final cs = Theme.of(context).colorScheme;
    switch (estado) {
      case 'RADICADA':
        return cs.primary;
      case 'EN_PROCESO':
        return Colors.orange;
      case 'RESUELTO':
        return Colors.green;
      case 'CERRADO':
        return cs.onPrimary;
      case 'RECHAZADA':
        return cs.error;
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _dotColor(context, entry.estadoNuevo);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Línea vertical + punto
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            if (!esUltimo)
              Container(
                width: 2,
                height: 52,
                color: cs.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: esUltimo ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado nuevo
                Text(
                  entry.estadoNuevoLegible,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                // Actor con marquee si es largo
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  child: _MarqueeText(
                    text: entry.actorLabel,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ),
                // Fecha
                if (entry.fechaCambio != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      DateFormatter.fechaHora12(entry.fechaCambio),
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ),
                // Comentario
                if (entry.comentario != null && entry.comentario!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        entry.comentario!,
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Marquee text ─────────────────────────────────────────────────────────────

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const _MarqueeText({required this.text, this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  final ScrollController _ctrl = ScrollController();
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarScroll());
  }

  Future<void> _iniciarScroll() async {
    if (!mounted || _animating) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final maxScroll = _ctrl.hasClients ? _ctrl.position.maxScrollExtent : 0.0;
    if (maxScroll <= 0) return;
    _animating = true;
    while (mounted) {
      await _ctrl.animateTo(
        maxScroll,
        duration: Duration(milliseconds: (maxScroll * 50).toInt().clamp(1000, 6000)),
        curve: Curves.linear,
      );
      if (!mounted) break;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) break;
      _ctrl.jumpTo(0);
      await Future.delayed(const Duration(milliseconds: 600));
    }
    _animating = false;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _ctrl,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}

// ─── Info row ────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _InfoRow({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icono, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$titulo: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(valor, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
