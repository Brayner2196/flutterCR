import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_moneda.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/plan_pago_model.dart';
import '../../providers/plan_pago_provider.dart';
import 'admin_detalle_plan_pago_screen.dart';

class AdminPlanesPagoScreen extends StatefulWidget {
  const AdminPlanesPagoScreen({super.key});

  @override
  State<AdminPlanesPagoScreen> createState() => _AdminPlanesPagoScreenState();
}

class _AdminPlanesPagoScreenState extends State<AdminPlanesPagoScreen> {
  String? _filtro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanPagoProvider>().cargarPlanesAdmin();
    });
  }

  Future<void> _aplicarFiltro(String? estado) async {
    setState(() => _filtro = estado);
    await context.read<PlanPagoProvider>().cargarPlanesAdmin(estado: estado);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlanPagoProvider>();
    final cs = Theme.of(context).colorScheme;

    final filtros = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(label: 'Todos', activo: _filtro == null,
                onTap: () => _aplicarFiltro(null)),
            const SizedBox(width: 6),
            _Chip(label: 'Pendientes', activo: _filtro == 'PENDIENTE',
                onTap: () => _aplicarFiltro('PENDIENTE')),
            const SizedBox(width: 6),
            _Chip(label: 'Activos', activo: _filtro == 'ACTIVO',
                onTap: () => _aplicarFiltro('ACTIVO')),
            const SizedBox(width: 6),
            _Chip(label: 'Completados', activo: _filtro == 'COMPLETADO',
                onTap: () => _aplicarFiltro('COMPLETADO')),
            const SizedBox(width: 6),
            _Chip(label: 'Rechazados', activo: _filtro == 'RECHAZADO',
                onTap: () => _aplicarFiltro('RECHAZADO')),
            const SizedBox(width: 6),
            _Chip(label: 'Incumplidos', activo: _filtro == 'INCUMPLIDO',
                onTap: () => _aplicarFiltro('INCUMPLIDO')),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Acuerdos de pago')),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<PlanPagoProvider>().cargarPlanesAdmin(estado: _filtro),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: filtros),

            if (p.loading && p.planes.isEmpty)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()))
            else if (p.planes.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment_outlined, size: 48, color: cs.outline),
                      const SizedBox(height: 12),
                      Text('Sin planes',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList.separated(
                  itemCount: p.planes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final plan = p.planes[i];
                    return _PlanTile(
                      plan: plan,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminDetallePlanPagoScreen(planId: plan.id),
                        ),
                      ).then((_) =>
                          context.read<PlanPagoProvider>().cargarPlanesAdmin(estado: _filtro)),
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

// ── Tile de plan ──────────────────────────────────────────────────────────────

class _PlanTile extends StatelessWidget {
  final PlanPagoModel plan;
  final VoidCallback onTap;

  const _PlanTile({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = _coloresEstado(plan.estado);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera ───────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(6)),
                  child: Text(plan.estadoLegible,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: fg)),
                ),
                Text(
                  '${plan.numeroCuotas} cuota${plan.numeroCuotas != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Residente y propiedad ─────────────────────────
            Row(children: [
              Icon(Icons.person_outline, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(plan.residenteNombre,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Icon(Icons.home_outlined, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(plan.propiedadIdentificador,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ]),
            const SizedBox(height: 4),

            // ── Fecha de la solicitud (zona del conjunto) ─────
            Row(children: [
              Icon(Icons.schedule, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Solicitado el ${DateFormatter.fechaHoraMinSegAmPm(plan.creadoEn)}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
            ]),
            const SizedBox(height: 10),

            // ── Montos: deuda | pago inicial | saldo a diferir ─
            // Tres columnas de igual ancho para que "Pago inicial" quede en el
            // centro exacto aunque los montos de los lados midan distinto.
            // La nota del recargo mantiene la cuenta a la vista:
            // deuda + recargo − pago inicial = saldo a diferir.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Monto(
                    label: 'Total deuda',
                    monto: plan.montoTotalDeuda,
                    nota: plan.montoRecargo > 0
                        ? '+ recargo ${FormatMoneda.format(plan.montoRecargo)}'
                        : null,
                  ),
                ),
                Expanded(
                  child: _Monto(
                    label: 'Pago inicial',
                    monto: plan.exigeAbonoInicial
                        ? plan.montoAbonoInicial
                        : null,
                    color: AppColors.blue,
                    alineacion: CrossAxisAlignment.center,
                  ),
                ),
                Expanded(
                  child: _Monto(
                    label: 'Total saldo a diferir',
                    monto: plan.montoDiferido,
                    bold: true,
                    alineacion: CrossAxisAlignment.end,
                  ),
                ),
              ],
            ),
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
      case 'INCUMPLIDO':
        return (AppColors.dangerSoft, AppColors.danger);
      default: // PENDIENTE
        return (AppColors.warningSoft, AppColors.warning);
    }
  }
}

/// Monto con su etiqueta, alineable a izquierda, centro o derecha.
/// [monto] null se muestra como "No aplica" (ej.: acuerdo sin pago inicial),
/// así la columna conserva su lugar y las otras no se corren.
class _Monto extends StatelessWidget {
  final String label;
  final double? monto;
  final Color? color;
  final bool bold;
  final CrossAxisAlignment alineacion;

  /// Línea pequeña debajo del monto (ej.: "+ recargo $ 120.000").
  final String? nota;

  const _Monto({
    required this.label,
    required this.monto,
    this.color,
    this.bold = false,
    this.alineacion = CrossAxisAlignment.start,
    this.nota,
  });

  TextAlign get _textAlign => switch (alineacion) {
        CrossAxisAlignment.center => TextAlign.center,
        CrossAxisAlignment.end => TextAlign.end,
        _ => TextAlign.start,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valor = monto;
    return Column(
      crossAxisAlignment: alineacion,
      children: [
        Text(label,
            textAlign: _textAlign,
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        Text(
          valor == null ? 'No aplica' : FormatMoneda.format(valor),
          textAlign: _textAlign,
          style: valor == null
              ? TextStyle(fontSize: 12, color: cs.onSurfaceVariant)
              : TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: color ?? cs.onSurface,
                ),
        ),
        if (nota != null)
          Text(nota!,
              textAlign: _textAlign,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _Chip(
      {required this.label, required this.activo, required this.onTap});

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
        child: Text(label,
            style: TextStyle(
              color: activo ? Colors.white : cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            )),
      ),
    );
  }
}
