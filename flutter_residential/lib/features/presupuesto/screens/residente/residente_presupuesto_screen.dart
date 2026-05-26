import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/categoria_presupuesto_model.dart';
import '../../models/presupuesto_model.dart';
import '../../providers/presupuesto_provider.dart';

/// Dashboard read-only de transparencia presupuestal para residentes.
class ResidentePresupuestoScreen extends StatefulWidget {
  const ResidentePresupuestoScreen({super.key});

  @override
  State<ResidentePresupuestoScreen> createState() =>
      _ResidentePresupuestoScreenState();
}

class _ResidentePresupuestoScreenState
    extends State<ResidentePresupuestoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PresupuestoProvider>().cargarActivo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PresupuestoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Presupuesto del conjunto')),
      body: RefreshIndicator(
        onRefresh: () => context.read<PresupuestoProvider>().cargarActivo(),
        child: Builder(builder: (_) {
          if (prov.loading && prov.activo == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.activo == null) {
            return _SinPresupuesto();
          }
          return _DashboardContent(presupuesto: prov.activo!);
        }),
      ),
    );
  }
}

// ── Contenido principal ────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final PresupuestoModel presupuesto;
  const _DashboardContent({required this.presupuesto});

  @override
  Widget build(BuildContext context) {
    final p = presupuesto;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Encabezado ───────────────────────────────────────
        _EncabezadoCard(presupuesto: p),
        const SizedBox(height: 20),

        // ── Categorías ────────────────────────────────────────
        _SectionLabel('Ejecución por categoría'),
        const SizedBox(height: 8),
        if (p.categorias.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('Sin categorías registradas',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          )
        else
          ...p.categorias.map((c) => _CategoriaRow(categoria: c)),
      ],
    );
  }
}

// ── Tarjeta de encabezado ─────────────────────────────────────────────────────

class _EncabezadoCard extends StatelessWidget {
  final PresupuestoModel presupuesto;
  const _EncabezadoCard({required this.presupuesto});

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = presupuesto;
    final pct = (p.porcentajeEjecucionGeneral / 100).clamp(0.0, 1.0);
    final Color barColor = p.tieneExcedidos ? AppColors.danger : AppColors.blue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue.withValues(alpha: 0.12),
            AppColors.blue.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_outlined,
                  size: 18, color: AppColors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.titulo?.isNotEmpty == true
                      ? p.titulo!
                      : 'Presupuesto ${p.anio}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Montos en fila
          Row(
            children: [
              _MontoInfo('Presupuestado', _fmt(p.montoTotalPresupuestado),
                  cs.onSurfaceVariant),
              const SizedBox(width: 16),
              _MontoInfo('Ejecutado', _fmt(p.montoTotalEjecutado), barColor),
              const SizedBox(width: 16),
              _MontoInfo(
                  'Disponible',
                  _fmt(p.montoTotalPendiente.clamp(0, double.infinity)),
                  AppColors.ok),
            ],
          ),
          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${p.porcentajeEjecucionGeneral.toStringAsFixed(1)}% del presupuesto ejecutado',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          if (p.tieneExcedidos) ...[
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.warning_amber_outlined,
                    size: 14, color: AppColors.warning),
                SizedBox(width: 6),
                Text('Algunas categorías superaron el presupuesto',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.warning)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MontoInfo extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  const _MontoInfo(this.label, this.valor, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(valor,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      );
}

// ── Fila de categoría ─────────────────────────────────────────────────────────

class _CategoriaRow extends StatelessWidget {
  final CategoriaPresupuestoModel categoria;
  const _CategoriaRow({required this.categoria});

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = categoria;
    final pct = (c.porcentajeEjecucion / 100).clamp(0.0, 1.0);
    final Color barColor = c.excedida ? AppColors.danger : AppColors.ok;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: c.excedida
              ? AppColors.danger.withValues(alpha: 0.3)
              : cs.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(c.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Text(_fmt(c.montoAsignado),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant)),
            ],
          ),
          if (c.descripcion?.isNotEmpty == true) ...[
            const SizedBox(height: 2),
            Text(c.descripcion!,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: 8),

          // Barra
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ejecutado: ${_fmt(c.montoEjecutado)} (${c.porcentajeEjecucion.toStringAsFixed(1)}%)',
                style: TextStyle(fontSize: 11, color: barColor),
              ),
              Text(
                c.excedida
                    ? 'Excedida'
                    : 'Disponible: ${_fmt(c.montoPendiente)}',
                style: TextStyle(
                    fontSize: 11,
                    color: c.excedida
                        ? AppColors.danger
                        : cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sin presupuesto ────────────────────────────────────────────────────────────

class _SinPresupuesto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_outlined, size: 56, color: cs.outline),
            const SizedBox(height: 16),
            Text('Sin presupuesto activo',
                style:
                    TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text(
              'El administrador aún no ha publicado\nun presupuesto para este año.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
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
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ));
}
