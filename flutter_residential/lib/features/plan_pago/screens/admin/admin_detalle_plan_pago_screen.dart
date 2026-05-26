import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/cuota_plan_model.dart';
import '../../models/plan_pago_model.dart';
import '../../providers/plan_pago_provider.dart';

class AdminDetallePlanPagoScreen extends StatefulWidget {
  final int planId;
  const AdminDetallePlanPagoScreen({super.key, required this.planId});

  @override
  State<AdminDetallePlanPagoScreen> createState() =>
      _AdminDetallePlanPagoScreenState();
}

class _AdminDetallePlanPagoScreenState
    extends State<AdminDetallePlanPagoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanPagoProvider>().cargarDetalle(widget.planId);
    });
  }

  Future<void> _aprobar() async {
    try {
      await context.read<PlanPagoProvider>().decidir(widget.planId, true);
      if (!mounted) return;
      _toast(ToastificationType.success, 'Plan aprobado — cuotas generadas');
    } catch (e) {
      if (!mounted) return;
      _toast(ToastificationType.error,
          e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _rechazar() async {
    final motivo = await _pedirMotivo('Motivo del rechazo');
    if (motivo == null || !mounted) return;
    try {
      await context
          .read<PlanPagoProvider>()
          .decidir(widget.planId, false, motivo: motivo);
      if (!mounted) return;
      _toast(ToastificationType.success, 'Solicitud rechazada');
    } catch (e) {
      if (!mounted) return;
      _toast(ToastificationType.error,
          e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _cancelar() async {
    final nota = await _pedirMotivo('Nota de cancelación (opcional)',
        required: false);
    if (!mounted) return;
    try {
      await context.read<PlanPagoProvider>().cancelar(widget.planId, nota: nota);
      if (!mounted) return;
      _toast(ToastificationType.success, 'Plan cancelado');
    } catch (e) {
      if (!mounted) return;
      _toast(ToastificationType.error,
          e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _marcarCuotaPagada(CuotaPlanModel cuota) async {
    final nota = await _pedirMotivo(
        'Nota del pago (opcional) — Cuota #${cuota.numeroCuota}',
        required: false);
    if (!mounted) return;
    try {
      await context
          .read<PlanPagoProvider>()
          .marcarCuotaPagada(widget.planId, cuota.id, nota: nota);
      if (!mounted) return;
      _toast(ToastificationType.success, 'Cuota #${cuota.numeroCuota} marcada como pagada');
    } catch (e) {
      if (!mounted) return;
      _toast(ToastificationType.error,
          e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<String?> _pedirMotivo(String titulo, {bool required = true}) =>
      showDialog<String>(
        context: context,
        builder: (_) {
          final ctrl = TextEditingController();
          return AlertDialog(
            title: Text(titulo),
            content: TextField(
              controller: ctrl,
              minLines: 2,
              maxLines: 4,
              decoration:
                  const InputDecoration(hintText: 'Escribe aquí...'),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              FilledButton(
                onPressed: () {
                  final text = ctrl.text.trim();
                  if (required && text.isEmpty) return;
                  Navigator.pop(context, text.isEmpty ? null : text);
                },
                style: FilledButton.styleFrom(
                    minimumSize: const Size(88, 44)),
                child: const Text('Confirmar'),
              ),
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
    final p = context.watch<PlanPagoProvider>();
    final plan = p.planDetalle;
    final cs = Theme.of(context).colorScheme;

    if (p.loading || plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del plan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final (bgEstado, fgEstado) = _coloresEstado(plan.estado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del plan'),
        actions: [
          if (plan.esActivo)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'cancelar') _cancelar();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'cancelar',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Cancelar plan'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<PlanPagoProvider>().cargarDetalle(widget.planId),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Header ────────────────────────────────────────
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: bgEstado,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(plan.estadoLegible,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: fgEstado)),
                      ),
                      Text(
                        _formatFecha(plan.creadoEn),
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Residente',
                      valor: plan.residenteNombre),
                  const SizedBox(height: 4),
                  _InfoRow(
                      icon: Icons.home_outlined,
                      label: 'Propiedad',
                      valor: plan.propiedadIdentificador),
                  if (plan.observaciones != null &&
                      plan.observaciones!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoRow(
                        icon: Icons.comment_outlined,
                        label: 'Observación',
                        valor: plan.observaciones!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Resumen financiero ────────────────────────────
            _InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen financiero',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.primary)),
                  const SizedBox(height: 10),
                  _MontoRow(
                      label: 'Deuda total',
                      monto: plan.montoTotalDeuda),
                  if (plan.montoRecargo > 0)
                    _MontoRow(
                        label: 'Recargo fraccionamiento',
                        monto: plan.montoRecargo,
                        color: AppColors.warning),
                  _MontoRow(
                      label: 'Total del plan',
                      monto: plan.montoTotalPlan,
                      bold: true),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${plan.numeroCuotas} cuota${plan.numeroCuotas != 1 ? 's' : ''}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        '\$${(plan.montoTotalPlan / plan.numeroCuotas).toStringAsFixed(0)} / cuota aprox.',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Motivo de rechazo / nota admin ────────────────
            if (plan.motivoRechazo != null) ...[
              _InfoCard(
                color: AppColors.dangerSoft,
                child: _InfoRow(
                    icon: Icons.info_outline,
                    label: 'Motivo rechazo',
                    valor: plan.motivoRechazo!,
                    iconColor: AppColors.danger),
              ),
              const SizedBox(height: 12),
            ],
            if (plan.notaAdmin != null && plan.notaAdmin!.isNotEmpty) ...[
              _InfoCard(
                child: _InfoRow(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'Nota admin',
                    valor: plan.notaAdmin!),
              ),
              const SizedBox(height: 12),
            ],

            // ── Cuotas ────────────────────────────────────────
            if (plan.cuotas.isNotEmpty) ...[
              Text('Cuotas del plan',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.primary)),
              const SizedBox(height: 8),
              ...plan.cuotas.map((c) => _CuotaTile(
                    cuota: c,
                    onMarcarPagada: plan.esActivo && !c.esPagada
                        ? () => _marcarCuotaPagada(c)
                        : null,
                  )),
              const SizedBox(height: 12),
            ],

            // ── Acciones PENDIENTE ────────────────────────────
            if (plan.esPendiente) ...[
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _rechazar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(
                            color: AppColors.danger.withValues(alpha: 0.5)),
                        minimumSize: const Size(88, 48),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _aprobar,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(88, 48)),
                      child: const Text('Aprobar'),
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

  (Color, Color) _coloresEstado(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return (AppColors.bgBlue, AppColors.blue);
      case 'COMPLETADO':
        return (AppColors.bgGreen, AppColors.ok);
      case 'RECHAZADO':
      case 'CANCELADO':
        return (AppColors.dangerSoft, AppColors.danger);
      default:
        return (AppColors.warningSoft, AppColors.warning);
    }
  }

  String _formatFecha(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso.length > 10 ? iso.substring(0, 10) : iso;
    }
  }
}

// ── Widgets de detalle ────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _InfoCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final Color? iconColor;

  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.valor,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: iconColor ?? cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text('$label: ',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        Expanded(
          child: Text(valor,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

class _MontoRow extends StatelessWidget {
  final String label;
  final double monto;
  final Color? color;
  final bool bold;

  const _MontoRow(
      {required this.label,
      required this.monto,
      this.color,
      this.bold = false});

  String _fmt(double v) => '\$${v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant)),
          Text(_fmt(monto),
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? cs.onSurface,
              )),
        ],
      ),
    );
  }
}

class _CuotaTile extends StatelessWidget {
  final CuotaPlanModel cuota;
  final VoidCallback? onMarcarPagada;

  const _CuotaTile({required this.cuota, this.onMarcarPagada});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bgColor;
    final Color fgColor;
    final IconData estadoIcon;

    if (cuota.esPagada) {
      bgColor = AppColors.bgGreen;
      fgColor = AppColors.ok;
      estadoIcon = Icons.check_circle_outline;
    } else if (cuota.vencida) {
      bgColor = AppColors.dangerSoft;
      fgColor = AppColors.danger;
      estadoIcon = Icons.warning_amber_outlined;
    } else {
      bgColor = AppColors.warningSoft;
      fgColor = AppColors.warning;
      estadoIcon = Icons.schedule_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fgColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(estadoIcon, size: 18, color: fgColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cuota ${cuota.numeroCuota}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  'Vence: ${cuota.fechaVencimiento}${cuota.fechaPago != null ? '  ·  Pagada: ${cuota.fechaPago}' : ''}',
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                if (cuota.notaPago != null)
                  Text(cuota.notaPago!,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            '\$${cuota.monto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13, color: fgColor),
          ),
          if (onMarcarPagada != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onMarcarPagada,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              color: AppColors.ok,
              tooltip: 'Marcar pagada',
              style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero),
            ),
          ],
        ],
      ),
    );
  }
}
