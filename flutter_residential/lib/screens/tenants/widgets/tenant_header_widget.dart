import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

/// Header rediseñado: banner tipo home residente + KPIs coloreados
class TenantHeaderWidget extends StatelessWidget {
  final int total;
  final int activos;
  final int inactivos;
  final String userName;

  const TenantHeaderWidget({
    super.key,
    required this.total,
    required this.activos,
    required this.inactivos,
    this.userName = 'Super Admin',
  });

  String get _primerNombre => userName.trim().split(' ').first;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner de bienvenida ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $_primerNombre 👋',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '🏢  Gestiona los conjuntos residenciales registrados.',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // ── Fila de KPIs coloreados ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: 'Total',
                  value: total.toString(),
                  icon: Icons.apartment_outlined,
                  color: cs.primary,
                  bgColor: cs.primary.withValues(alpha: 0.08),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  label: 'Activos',
                  value: activos.toString(),
                  icon: Icons.check_circle_outline,
                  color: AppColors.ok,
                  bgColor: AppColors.okSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(
                  label: 'Inactivos',
                  value: inactivos.toString(),
                  icon: Icons.block_outlined,
                  color: cs.onSurfaceVariant,
                  bgColor: cs.surfaceContainerHighest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: color.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
