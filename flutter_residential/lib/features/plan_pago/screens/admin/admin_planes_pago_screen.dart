import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
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
  String? _filtro = 'PENDIENTE';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanPagoProvider>().cargarPlanesAdmin(estado: 'PENDIENTE');
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
            _Chip(label: 'Todos', activo: _filtro == null,
                onTap: () => _aplicarFiltro(null)),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Planes de pago')),
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
            const SizedBox(height: 6),

            // ── Montos ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Monto(label: 'Deuda', monto: plan.montoTotalDeuda),
                if (plan.montoRecargo > 0)
                  _Monto(label: 'Recargo', monto: plan.montoRecargo,
                      color: AppColors.warning),
                _Monto(label: 'Total plan', monto: plan.montoTotalPlan,
                    bold: true),
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
        return (AppColors.dangerSoft, AppColors.danger);
      default: // PENDIENTE
        return (AppColors.warningSoft, AppColors.warning);
    }
  }
}

class _Monto extends StatelessWidget {
  final String label;
  final double monto;
  final Color? color;
  final bool bold;

  const _Monto(
      {required this.label, required this.monto, this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        Text(
          '\$${monto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? cs.onSurface,
          ),
        ),
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
