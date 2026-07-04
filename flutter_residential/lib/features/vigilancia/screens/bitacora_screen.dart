import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'package:flutter_residential/core/utils/date_formatter.dart';
import '../models/bitacora_acceso_model.dart';
import '../providers/vigilancia_provider.dart';

/// Minuta de eventos de portería (solo lectura).
class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({super.key});

  @override
  State<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<VigilanciaProvider>().cargarBitacora());
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<VigilanciaProvider>();
    final eventos = prov.bitacora;

    return RefreshIndicator(
      onRefresh: () => prov.cargarBitacora(),
      child: prov.loading && eventos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : eventos.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.history_rounded, size: 64, color: AppColors.textLoLight),
                    SizedBox(height: AppSpacing.md),
                    Center(child: Text('Sin novedades registradas')),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: eventos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => _EventoTile(evento: eventos[i]),
                ),
    );
  }
}

class _EventoTile extends StatelessWidget {
  final BitacoraAccesoModel evento;

  const _EventoTile({required this.evento});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color fg;
    final Color bg;
    if (evento.esDenegado) {
      fg = AppColors.danger;
      bg = AppColors.dangerSoft;
    } else if (evento.esPermitido) {
      fg = AppColors.ok;
      bg = AppColors.okSoft;
    } else {
      fg = AppColors.blue;
      bg = AppColors.bgBlue;
    }

    final icono = switch (evento.tipoEvento) {
      'ACCESO_VEHICULAR' => Icons.directions_car_rounded,
      'ACCESO_PEATONAL' => Icons.directions_walk_rounded,
      'VISITA_VALIDADA' => Icons.qr_code_2_rounded,
      'PAQUETE_RECIBIDO' => Icons.inventory_2_rounded,
      'PAQUETE_ENTREGADO' => Icons.assignment_turned_in_rounded,
      _ => Icons.event_note_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icono, color: fg, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(evento.tipoLegible,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(evento.resultado,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
                  ],
                ),
                if (evento.descripcion != null && evento.descripcion!.isNotEmpty)
                  Text(evento.descripcion!,
                      style: theme.textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  '${evento.propiedadIdentificador != null ? 'Unidad ${evento.propiedadIdentificador} · ' : ''}'
                  '${DateFormatter.fechaHoraMinAmPm(evento.creadoEn)}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
