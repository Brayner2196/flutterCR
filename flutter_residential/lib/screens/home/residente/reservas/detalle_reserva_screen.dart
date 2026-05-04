import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../models/reserva_model.dart';
import '../../../../providers/reserva_provider.dart';
import '../../../../shared/widgets/estado_badge.dart';
import '../../../../shared/widgets/confirm_dialog.dart';

class DetalleReservaScreen extends StatefulWidget {
  final ReservaModel reserva;

  const DetalleReservaScreen({super.key, required this.reserva});

  @override
  State<DetalleReservaScreen> createState() => _DetalleReservaScreenState();
}

class _DetalleReservaScreenState extends State<DetalleReservaScreen> {
  late ReservaModel _reserva;

  @override
  void initState() {
    super.initState();
    _reserva = widget.reserva;
  }

  Future<void> _cancelar() async {
    final confirmado = await ConfirmDialog.mostrar(
      context: context,
      titulo: 'Cancelar reserva',
      mensaje:
          '¿Estás seguro de que deseas cancelar esta reserva en ${_reserva.zonaComunNombre}?',
      textoConfirmar: 'Sí, cancelar',
      colorConfirmar: Colors.red,
    );
    if (!confirmado || !mounted) return;

    try {
      final actualizada =
          await context.read<ReservaProvider>().cancelarReserva(_reserva.id);
      setState(() => _reserva = actualizada);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Reserva cancelada'),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Reserva')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Estado ──────────────────────────
            Center(
              child: EstadoBadge(
                estado: _reserva.estado,
                label: _reserva.estadoLegible,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Zona común ──────────────────────
            _SeccionInfo(
              icono: Icons.location_on_outlined,
              titulo: 'Zona Común',
              valor: _reserva.zonaComunNombre,
            ),
            const SizedBox(height: 16),

            // ─── Fecha ───────────────────────────
            _SeccionInfo(
              icono: Icons.calendar_today_outlined,
              titulo: 'Fecha',
              valor: _reserva.fecha,
            ),
            const SizedBox(height: 16),

            // ─── Horario ─────────────────────────
            _SeccionInfo(
              icono: Icons.schedule_outlined,
              titulo: 'Horario',
              valor: '${_reserva.horaInicio} — ${_reserva.horaFin}',
            ),
            const SizedBox(height: 16),

            // ─── Observaciones ───────────────────
            if (_reserva.observaciones != null &&
                _reserva.observaciones!.isNotEmpty) ...[
              _SeccionInfo(
                icono: Icons.notes_outlined,
                titulo: 'Observaciones',
                valor: _reserva.observaciones!,
              ),
              const SizedBox(height: 16),
            ],

            // ─── Fecha de creación ───────────────
            if (_reserva.creadoEn != null) ...[
              _SeccionInfo(
                icono: Icons.access_time_outlined,
                titulo: 'Creada el',
                valor: _reserva.creadoEn!,
              ),
              const SizedBox(height: 16),
            ],

            // ─── Motivo de rechazo ───────────────
            if (_reserva.esRechazada &&
                _reserva.motivoDecision != null &&
                _reserva.motivoDecision!.isNotEmpty) ...[
              const Divider(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Motivo del rechazo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.error,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _reserva.motivoDecision!,
                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                    ),
                  ],
                ),
              ),
            ],

            // ─── Botón cancelar ──────────────────
            if (_reserva.esPendiente) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancelar,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancelar Reserva'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeccionInfo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;

  const _SeccionInfo({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
