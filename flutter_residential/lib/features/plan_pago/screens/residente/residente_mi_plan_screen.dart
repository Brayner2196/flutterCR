import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_moneda.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/panel_tiles.dart';
import '../../models/plan_pago_model.dart';
import '../../providers/plan_pago_provider.dart';
import '../../widgets/lista_cobros_acuerdo.dart';
import '../../widgets/preview_acuerdo_pago.dart';

/// Vista del residente: acuerdo vigente e historial.
///
/// El acuerdo vigente se pide aparte de la lista porque es el único que trae
/// sus cobros: el listado es un resumen y el detalle es el que manda.
class ResidenteMiPlanScreen extends StatefulWidget {
  const ResidenteMiPlanScreen({super.key});

  @override
  State<ResidenteMiPlanScreen> createState() => _ResidenteMiPlanScreenState();
}

class _ResidenteMiPlanScreenState extends State<ResidenteMiPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final p = context.read<PlanPagoProvider>();
    await p.cargarMisPlanes();
    await p.cargarPlanActivo();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlanPagoProvider>();

    if (p.loading && p.planes.isEmpty && p.planActivo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi acuerdo de pago')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final vigente = p.planActivo;
    final historial = p.planes.where((pl) => !pl.estaVigente).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi acuerdo de pago')),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (vigente != null) ...[
              _Etiqueta(vigente.esPendiente
                  ? 'Solicitud en revisión'
                  : 'Acuerdo vigente'),
              const SizedBox(height: 8),
              vigente.esPendiente
                  ? _SolicitudPendienteCard(plan: vigente)
                  : _AcuerdoActivoCard(plan: vigente),
              const SizedBox(height: 22),
            ],

            if (vigente == null && historial.isEmpty)
              const _Vacio('No tienes acuerdos de pago'),

            if (historial.isNotEmpty) ...[
              const _Etiqueta('Historial'),
              const SizedBox(height: 8),
              ...historial.map((pl) => _HistorialTile(plan: pl)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Acuerdo activo ───────────────────────────────────────────────────────────

class _AcuerdoActivoCard extends StatelessWidget {
  final PlanPagoModel plan;
  const _AcuerdoActivoCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inicial = plan.cobroInicial;
    final inicialPendiente =
        inicial != null && !inicial.esPagado && inicial.sePuedePagar;

    return PanelTiles(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Acuerdo #${plan.id}',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w800)),
                      Text(
                        'Celebrado el ${DateFormatter.fechaHoraMinAmPm(plan.fechaDecision ?? plan.creadoEn)}',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bgBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(plan.estadoLegible,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Aviso del abono inicial ───────────────────
            if (inicialPendiente)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Falta el pago inicial',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paga ${FormatMoneda.format(inicial.montoPendiente)} '
                      'antes del ${DateFormatter.fecha(plan.fechaLimiteInicial)} '
                      'desde tu estado de cuenta. Si no, el acuerdo se incumple '
                      'y vuelve tu deuda original.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.warning),
                    ),
                  ],
                ),
              ),

            // ── Progreso ──────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: plan.progreso,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${FormatMoneda.format(plan.montoPagadoAcuerdo)} pagado de '
              '${FormatMoneda.format(plan.montoTotalPlan)}  ·  '
              '${plan.cuotasPagadas} de ${plan.numeroCuotas} cuotas',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // ── Cobros del acuerdo ────────────────────────
            const _Etiqueta('Pagos del acuerdo'),
            const SizedBox(height: 8),
            ListaCobrosAcuerdo(cobros: plan.cobros),
            const SizedBox(height: 4),
            Text(
              'Cada uno aparece en tu estado de cuenta y se paga como cualquier cobro.',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Solicitud pendiente ──────────────────────────────────────────────────────

class _SolicitudPendienteCard extends StatelessWidget {
  final PlanPagoModel plan;
  const _SolicitudPendienteCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PanelTiles(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hourglass_top_outlined,
                    size: 18, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tu solicitud está en revisión',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Todavía no debes pagar nada. Cuando el administrador la apruebe '
              'se generan el pago inicial y las cuotas.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            PreviewAcuerdoPago.deAcuerdo(plan),
          ],
        ),
      ),
    );
  }
}

// ── Historial ────────────────────────────────────────────────────────────────

class _HistorialTile extends StatelessWidget {
  final PlanPagoModel plan;
  const _HistorialTile({required this.plan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _colores(cs);

    return PanelTiles(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Acuerdo #${plan.id}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    'Creado el: ${DateFormatter.fechaHoraMinSegAmPm(plan.creadoEn)}',
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  if (plan.esRechazado && plan.motivoRechazo != null)
                    Text('Motivo: ${plan.motivoRechazo}',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant)),
                  if (plan.esCancelado && plan.notaAdmin != null)
                    Text('Motivo: ${plan.notaAdmin}',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant)),
                  if (plan.esIncumplido)
                    Text(
                      'El pago inicial no se realizó a tiempo; tu deuda original volvió a quedar activa.',
                      style:
                          TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(plan.estadoLegible,
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
                ),
                Text(
                  FormatMoneda.format(plan.montoTotalPlan),
                  style: TextStyle(
                    color: fg,
                    fontSize: 16
                  ),
                )
              ],
            )
            
          ],
        ),
      ),
    );
  }

  (Color, Color) _colores(ColorScheme cs) {
    if (plan.esCompletado) return (AppColors.bgBlue, AppColors.blue);
    if (plan.esCancelado) return (AppColors.dangerSoft ,AppColors.danger);
    if (plan.esIncumplido || plan.esRechazado) return (AppColors.warningSoft, AppColors.warning);
    
    return (cs.surfaceContainerHighest, cs.onSurfaceVariant);
  }
}

// ── Auxiliares ───────────────────────────────────────────────────────────────

class _Etiqueta extends StatelessWidget {
  final String text;
  const _Etiqueta(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: cs.primary,
          letterSpacing: 0.4,
        ));
  }
}

class _Vacio extends StatelessWidget {
  final String texto;
  const _Vacio(this.texto);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(texto,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
      ),
    );
  }
}
