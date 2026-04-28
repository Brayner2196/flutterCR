import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../../models/reserva_model.dart';
import '../../../../../providers/reserva_provider.dart';
import '../../widgets/dashboard/dashboard_tokens.dart';

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
      context.read<ReservaProvider>().cargarAdmin(estado: _filtro);
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
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Reserva aprobada'),
        autoCloseDuration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(e.toString()),
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _rechazar(ReservaModel r) async {
    final motivo = await _pedirMotivo();
    if (motivo == null) return;
    try {
      await context.read<ReservaProvider>().rechazar(r.id, motivo);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Reserva rechazada'),
        autoCloseDuration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(e.toString()),
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  Future<String?> _pedirMotivo() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motivo del rechazo'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Describe el motivo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReservaProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reservas')),
      body: RefreshIndicator(
        onRefresh: () => context.read<ReservaProvider>().cargarAdmin(estado: _filtro),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
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
            ),
            if (p.error != null && p.reservas.isEmpty)
              Expanded(child: Center(child: Text(p.error!, style: TextStyle(color: cs.error))))
            else if (p.loading && p.reservas.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (p.reservas.isEmpty)
              const Expanded(child: Center(child: Text('Sin reservas')))
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
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _FiltroChip({required this.label, required this.activo, required this.onTap});

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
    Color bg;
    Color fg;
    switch (reserva.estado) {
      case 'PENDIENTE':
        bg = DashboardTokens.bgYellow;
        fg = DashboardTokens.fgYellow;
        break;
      case 'APROBADA':
        bg = DashboardTokens.bgGreen;
        fg = DashboardTokens.fgGreen;
        break;
      case 'RECHAZADA':
      case 'CANCELADA':
        bg = DashboardTokens.bgRed;
        fg = DashboardTokens.fgRed;
        break;
      default:
        bg = cs.surfaceContainerHighest;
        fg = cs.onSurfaceVariant;
    }

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
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  reserva.estadoLegible,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
                ),
              ),
              Text(
                reserva.fecha,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reserva.zonaComunNombre,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${reserva.horaInicio} — ${reserva.horaFin}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          if (reserva.observaciones != null && reserva.observaciones!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reserva.observaciones!,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person_outline, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(reserva.residenteNombre,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
          if (reserva.esPendiente) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onRechazar,
                  child: const Text('Rechazar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onAprobar,
                  child: const Text('Aprobar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
