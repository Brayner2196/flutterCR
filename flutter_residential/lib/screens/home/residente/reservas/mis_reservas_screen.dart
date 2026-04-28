import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/reserva_model.dart';
import '../../../../providers/reserva_provider.dart';
import '../../../../widgets/shared/estado_badge.dart';
import '../../../../widgets/shared/filtro_chips.dart';
import '../../../../widgets/shared/empty_state_widget.dart';
import 'crear_reserva_screen.dart';
import 'detalle_reserva_screen.dart';

class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({super.key});

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen> {
  String? _filtro;

  static const _filtros = [
    FiltroOption(label: 'Todas', valor: null),
    FiltroOption(label: 'Pendientes', valor: 'PENDIENTE'),
    FiltroOption(label: 'Aprobadas', valor: 'APROBADA'),
    FiltroOption(label: 'Rechazadas', valor: 'RECHAZADA'),
    FiltroOption(label: 'Canceladas', valor: 'CANCELADA'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservaProvider>().cargarMisReservas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ReservaProvider>();
    final cs = Theme.of(context).colorScheme;
    final reservasFiltradas = p.filtrarPorEstado(_filtro);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reservas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _irACrear(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ReservaProvider>().cargarMisReservas(),
        child: Column(
          children: [
            FiltroChips(
              opciones: _filtros,
              valorActual: _filtro,
              onSeleccionar: (v) => setState(() => _filtro = v),
            ),
            if (p.error != null && p.reservas.isEmpty)
              Expanded(
                child: Center(
                  child: Text(p.error!, style: TextStyle(color: cs.error)),
                ),
              )
            else if (p.loading && p.reservas.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (reservasFiltradas.isEmpty)
              Expanded(
                child: EmptyStateWidget(
                  icono: Icons.event_busy_outlined,
                  mensaje: 'No tienes reservas',
                  textoBoton: 'Nueva Reserva',
                  onBoton: () => _irACrear(),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: reservasFiltradas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _ReservaTile(
                    reserva: reservasFiltradas[i],
                    onTap: () => _irADetalle(reservasFiltradas[i]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _irACrear() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrearReservaScreen()),
    ).then((_) => context.read<ReservaProvider>().cargarMisReservas());
  }

  void _irADetalle(ReservaModel reserva) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleReservaScreen(reserva: reserva),
      ),
    );
  }
}

class _ReservaTile extends StatelessWidget {
  final ReservaModel reserva;
  final VoidCallback onTap;

  const _ReservaTile({required this.reserva, required this.onTap});

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                EstadoBadge(
                  estado: reserva.estado,
                  label: reserva.estadoLegible,
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
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${reserva.horaInicio} — ${reserva.horaFin}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            if (reserva.observaciones != null &&
                reserva.observaciones!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                reserva.observaciones!,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
