import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/cuota_plan_model.dart';
import '../../models/plan_pago_model.dart';
import '../../providers/plan_pago_provider.dart';

/// Vista del residente: plan activo o historial de planes.
class ResidenteMiPlanScreen extends StatefulWidget {
  const ResidenteMiPlanScreen({super.key});

  @override
  State<ResidenteMiPlanScreen> createState() => _ResidenteMiPlanScreenState();
}

class _ResidenteMiPlanScreenState extends State<ResidenteMiPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanPagoProvider>().cargarMisPlanes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlanPagoProvider>();

    if (p.loading && p.planes.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi plan de pago')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Plan activo o pendiente primero
    final planActivo = p.planes.where((pl) => pl.esActivo).firstOrNull;
    final planPendiente =
        p.planes.where((pl) => pl.esPendiente).firstOrNull;
    final historial = p.planes
        .where((pl) => pl.esCompletado || pl.esRechazado || pl.esCancelado)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mi plan de pago')),
      body: RefreshIndicator(
        onRefresh: () => context.read<PlanPagoProvider>().cargarMisPlanes(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Plan activo ────────────────────────────────
            if (planActivo != null) ...[
              _SectionLabel('Plan activo'),
              const SizedBox(height: 8),
              _PlanActivoCard(plan: planActivo),
              const SizedBox(height: 20),
            ],

            // ── Solicitud pendiente ────────────────────────
            if (planPendiente != null) ...[
              _SectionLabel('Solicitud en revisión'),
              const SizedBox(height: 8),
              _PendienteCard(plan: planPendiente),
              const SizedBox(height: 20),
            ],

            // ── Sin planes activos ─────────────────────────
            if (planActivo == null && planPendiente == null && historial.isEmpty)
              _SinPlanesWidget(),

            // ── Historial ──────────────────────────────────
            if (historial.isNotEmpty) ...[
              _SectionLabel('Historial'),
              const SizedBox(height: 8),
              ...historial.map((pl) => _HistorialTile(plan: pl)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Plan activo con cuotas ────────────────────────────────────────────────────

class _PlanActivoCard extends StatelessWidget {
  final PlanPagoModel plan;
  const _PlanActivoCard({required this.plan});

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progreso =
        plan.numeroCuotas > 0 ? plan.cuotasPagadas / plan.numeroCuotas : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Resumen ───────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total del plan',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              Text(_fmt(plan.montoTotalPlan),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pagado: ${_fmt(plan.montoPagado)}',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.ok)),
              Text('Pendiente: ${_fmt(plan.montoPendiente)}',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),

          // ── Barra de progreso ─────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.ok),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${plan.cuotasPagadas} de ${plan.numeroCuotas} cuotas pagadas',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          // ── Cuotas ────────────────────────────────────────
          Text('Cuotas',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.primary)),
          const SizedBox(height: 8),
          if (plan.cuotas.isEmpty)
            Text('Cargando cuotas...',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12))
          else
            ...plan.cuotas.map((c) => _ResidenteCuotaTile(cuota: c)),
        ],
      ),
    );
  }
}

class _ResidenteCuotaTile extends StatelessWidget {
  final CuotaPlanModel cuota;
  const _ResidenteCuotaTile({required this.cuota});

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color bg;
    final Color fg;
    final IconData icon;

    if (cuota.esPagada) {
      bg = AppColors.bgGreen;
      fg = AppColors.ok;
      icon = Icons.check_circle_outline;
    } else if (cuota.vencida) {
      bg = AppColors.dangerSoft;
      fg = AppColors.danger;
      icon = Icons.warning_amber_outlined;
    } else {
      bg = AppColors.warningSoft;
      fg = AppColors.warning;
      icon = Icons.schedule_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuota ${cuota.numeroCuota}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  cuota.esPagada
                      ? 'Pagada el ${cuota.fechaPago}'
                      : 'Vence: ${cuota.fechaVencimiento}',
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            _fmt(cuota.monto),
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: fg),
          ),
        ],
      ),
    );
  }
}

// ── Plan pendiente ────────────────────────────────────────────────────────────

class _PendienteCard extends StatelessWidget {
  final PlanPagoModel plan;
  const _PendienteCard({required this.plan});

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_outlined,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              const Text('En espera de aprobación',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Solicitaste fraccionar ${_fmt(plan.montoTotalDeuda)} en ${plan.numeroCuotas} cuota${plan.numeroCuotas != 1 ? 's' : ''}.',
            style: TextStyle(fontSize: 13, color: cs.onSurface),
          ),
          if (plan.montoRecargo > 0) ...[
            const SizedBox(height: 4),
            Text('Recargo: ${_fmt(plan.montoRecargo)}',
                style: TextStyle(fontSize: 12, color: AppColors.warning)),
          ],
          const SizedBox(height: 4),
          Text('Total del plan: ${_fmt(plan.montoTotalPlan)}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
          if (plan.observaciones != null &&
              plan.observaciones!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Nota: ${plan.observaciones}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

// ── Historial tile ────────────────────────────────────────────────────────────

class _HistorialTile extends StatelessWidget {
  final PlanPagoModel plan;
  const _HistorialTile({required this.plan});

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;

    if (plan.esCompletado) {
      bg = AppColors.bgGreen;
      fg = AppColors.ok;
    } else {
      bg = AppColors.dangerSoft;
      fg = AppColors.danger;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.estadoLegible,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: fg)),
                Text(
                  '${plan.numeroCuotas} cuotas · ${_fmt(plan.montoTotalPlan)}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                if (plan.motivoRechazo != null)
                  Text(plan.motivoRechazo!,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sin planes ────────────────────────────────────────────────────────────────

class _SinPlanesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.payment_outlined, size: 48, color: cs.outline),
            const SizedBox(height: 12),
            Text('No tienes planes de pago',
                style:
                    TextStyle(fontSize: 15, color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Ve a tu estado de cuenta para solicitar uno.',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: cs.primary,
          letterSpacing: 0.5,
        ));
  }
}
