import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/pqr_model.dart';
import '../../../../providers/pqr_provider.dart';
import '../../../../widgets/shared/estado_badge.dart';
import '../../../../widgets/shared/filtro_chips.dart';
import '../../../../widgets/shared/empty_state_widget.dart';
import 'crear_pqr_screen.dart';
import 'detalle_pqr_screen.dart';

class MisPqrsScreen extends StatefulWidget {
  const MisPqrsScreen({super.key});

  @override
  State<MisPqrsScreen> createState() => _MisPqrsScreenState();
}

class _MisPqrsScreenState extends State<MisPqrsScreen> {
  String? _filtro;

  static const _filtros = [
    FiltroOption(label: 'Todas', valor: null),
    FiltroOption(label: 'Pendientes', valor: 'PENDIENTE'),
    FiltroOption(label: 'En proceso', valor: 'EN_PROCESO'),
    FiltroOption(label: 'Resueltas', valor: 'RESUELTO'),
    FiltroOption(label: 'Cerradas', valor: 'CERRADO'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PqrProvider>().cargarMisPqrs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PqrProvider>();
    final cs = Theme.of(context).colorScheme;
    final pqrsFiltradas = p.filtrarPorEstado(_filtro);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis PQRs')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _irACrear(),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<PqrProvider>().cargarMisPqrs(),
        child: Column(
          children: [
            FiltroChips(
              opciones: _filtros,
              valorActual: _filtro,
              onSeleccionar: (v) => setState(() => _filtro = v),
            ),
            if (p.error != null && p.pqrs.isEmpty)
              Expanded(
                child: Center(
                  child: Text(p.error!, style: TextStyle(color: cs.error)),
                ),
              )
            else if (p.loading && p.pqrs.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (pqrsFiltradas.isEmpty)
              Expanded(
                child: EmptyStateWidget(
                  icono: Icons.support_agent_outlined,
                  mensaje: 'No tienes solicitudes',
                  textoBoton: 'Nueva Solicitud',
                  onBoton: () => _irACrear(),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: pqrsFiltradas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PqrTile(
                    pqr: pqrsFiltradas[i],
                    onTap: () => _irADetalle(pqrsFiltradas[i]),
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
      MaterialPageRoute(builder: (_) => const CrearPqrScreen()),
    ).then((_) => context.read<PqrProvider>().cargarMisPqrs());
  }

  void _irADetalle(PqrModel pqr) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetallePqrScreen(pqr: pqr)),
    );
  }
}

class _PqrTile extends StatelessWidget {
  final PqrModel pqr;
  final VoidCallback onTap;

  const _PqrTile({required this.pqr, required this.onTap});

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
                EstadoBadge(
                  estado: pqr.estado,
                  label: pqr.estadoLegible,
                ),
                const SizedBox(width: 8),
                _TipoBadge(tipo: pqr.tipo, label: pqr.tipoLegible),
                const Spacer(),
                if (pqr.creadoEn != null)
                  Text(
                    pqr.creadoEn!.substring(0, 10),
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
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
            Text(
              pqr.descripcion,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (pqr.respuestaAdmin != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.reply, size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Respuesta disponible',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TipoBadge extends StatelessWidget {
  final String tipo;
  final String label;

  const _TipoBadge({required this.tipo, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }
}
