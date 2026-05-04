import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

/// Header del diseño V1: saludo + KPIs (total, activos, inactivos)
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
    this.userName = 'Super Admin Bray',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, $userName',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Kpi(label: 'Total', value: total.toString()),
                ),
                _VDivider(),
                Expanded(
                  child: _Kpi(
                    label: 'Activos',
                    value: activos.toString(),
                    dot: AppColors.ok,
                  ),
                ),
                _VDivider(),
                Expanded(
                  child: _Kpi(
                    label: 'Inactivos',
                    value: inactivos.toString(),
                    dot: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final Color? dot;
  const _Kpi({required this.label, required this.value, this.dot});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (dot != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }
}
