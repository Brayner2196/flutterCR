import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/reserva_model.dart';
import '../../providers/reserva_provider.dart';

class AdminReservasScreen extends StatefulWidget {
  const AdminReservasScreen({super.key});

  @override
  State<AdminReservasScreen> createState() => _AdminReservasScreenState();
}

class _AdminReservasScreenState extends State<AdminReservasScreen> {
  String? _filtro = 'PENDIENTE';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservaProvider>().cargarAdmin(estado: 'PENDIENTE');
    });
  }

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

    // Widget de filtros reutilizable en el sliver
    final filtrosWidget = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FiltroChip(
              label: 'Pendientes',
              activo: _filtro == 'PENDIENTE',
              onTap: () => _aplicarFiltro('PENDIENTE'),
            ),
            const SizedBox(width: 6),
            _FiltroChip(
              label: 'Aprobadas',
              activo: _filtro == 'APROBADA',
              onTap: () => _aplicarFiltro('APROBADA'),
            ),
            const SizedBox(width: 6),
            _FiltroChip(
              label: 'Rechazadas',
              activo: _filtro == 'RECHAZADA',
              onTap: () => _aplicarFiltro('RECHAZADA'),
            ),
            const SizedBox(width: 6),
            _FiltroChip(
              label: 'Todas',
              activo: _filtro == null,
              onTap: () => _aplicarFiltro(null),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de reserva'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<ReservaProvider>().cargarAdmin(estado: _filtro),
        child: CustomScrollView(
          slivers: [
            // ── Filtros ─────────────────────────────────────────────
            SliverToBoxAdapter(child: filtrosWidget),

            // ── Cargando ─────────────────────────────────────────────
            if (p.loading && p.reservas.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )

            // ── Sin resultados ────────────────────────────────────────
            else if (p.reservas.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_outlined,
                          size: 48, color: cs.outline),
                      const SizedBox(height: 12),
                      Text(
                        'Sin solicitudes',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )

            // ── Lista ─────────────────────────────────────────────────
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.separated(
                  itemCount: p.reservas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final reserva = p.reservas[i];
                    return _ReservaTile(
                      reserva: reserva,
                      onAprobar: () => _aprobar(reserva),
                      onRechazar: () => _rechazar(reserva),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
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
          // ── Cabecera: estado + fecha ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  reserva.estadoLegible,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: fg),
                ),
              ),
              Text(
                reserva.fecha,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Zona y horario ────────────────────────────────────────
          Text(
            reserva.zonaComunNombre,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormatter.hora12Texto(reserva.horaInicio)} — ${DateFormatter.hora12Texto(reserva.horaFin)}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),

          // ── Observaciones ─────────────────────────────────────────
          if (reserva.observaciones?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              reserva.observaciones!,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ── Residente ─────────────────────────────────────────────
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.person_outline, size: 12, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              reserva.residenteNombre,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ]),

          // ── Botones de acción (solo PENDIENTE) ────────────────────
          if (reserva.esPendiente) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onRechazar,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
                    // Evitar que el tema global (Size.fromHeight) force ancho infinito
                    minimumSize: const Size(88, 44),
                  ),
                  child: const Text('Rechazar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onAprobar,
                  style: FilledButton.styleFrom(
                    // El tema global usa Size.fromHeight(48) = ancho infinito,
                    // lo que rompe el layout dentro de un Row sin Expanded.
                    minimumSize: const Size(88, 44),
                  ),
                  child: const Text('Aprobar'),
                ),
              ],
            ),
          ],

          // ── Motivo de decisión ────────────────────────────────────
          if (reserva.motivoDecision != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    reserva.motivoDecision!,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  (Color, Color) _coloresEstado(String estado, ColorScheme cs) {
    switch (estado) {
      case 'APROBADA':
        return (AppColors.bgGreen, AppColors.ok);
      case 'RECHAZADA':
        return (AppColors.dangerSoft, AppColors.danger);
      case 'CANCELADA':
        return (AppColors.dangerSoft, AppColors.danger);
      default:
        return (AppColors.warningSoft, AppColors.warning);
    }
  }
}

// ── Chip de filtro ────────────────────────────────────────────────────────────

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
