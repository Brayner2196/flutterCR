import 'package:flutter/material.dart';
import 'package:flutter_residential/theme/app_theme.dart';
import '../../../models/tenant_response.dart';


/// Card del diseño V1:
/// - monograma con fondo teñido según id
/// - nombre + chip de estado
/// - código (mono) + dirección
/// - métricas inferiores: usuarios (destacado) + schema (mono)
class TenantCard extends StatelessWidget {
  final TenantResponse tenant;
  final int? usuariosCount; // opcional, mock si no hay backend
  final VoidCallback onEditar;
  final VoidCallback onDesactivar;
  final VoidCallback onActivar;

  const TenantCard({
    super.key,
    required this.tenant,
    required this.onEditar,
    required this.onDesactivar,
    required this.onActivar,
    this.usuariosCount,
  });

  String _initials(String name) {
    final parts =
        name.split(' ').where((w) => w.length > 2).take(2).toList();
    if (parts.isEmpty) return name.substring(0, 1).toUpperCase();
    return parts.map((w) => w[0]).join().toUpperCase();
  }

  Color _monoBg(BuildContext context) {
    final hues = [
      const Color(0xFFEDE9FB), // violeta
      const Color(0xFFE4EAF4), // azul
      const Color(0xFFE0EEE9), // verde
      const Color(0xFFF4EAD9), // ocre
      const Color(0xFFF4E2E8), // rosa
      const Color(0xFFE3ECE6), // teal
    ];
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) return Theme.of(context).colorScheme.surfaceContainerHighest;
    return hues[tenant.id % hues.length];
  }

  Color _monoFg() {
    const fgs = [
      Color(0xFF4A3FB0),
      Color(0xFF2F5490),
      Color(0xFF2F6B50),
      Color(0xFF8A6217),
      Color(0xFF9C3B57),
      Color(0xFF346A5E),
    ];
    return fgs[tenant.id % fgs.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final activo = tenant.activo;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top row: monograma + nombre + estado ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _monoBg(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(tenant.nombre),
                    style: TextStyle(
                      color: _monoFg(),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tenant.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(activo: activo),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            tenant.codigo,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurfaceVariant,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (tenant.direccion != null &&
                              tenant.direccion!.isNotEmpty) ...[
                            Text(
                              ' · ',
                              style: TextStyle(color: cs.outline),
                            ),
                            Expanded(
                              child: Text(
                                tenant.direccion!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: cs.outlineVariant),
            const SizedBox(height: 12),

            // ─── Bottom row: métricas + menú ───
            Row(
              children: [
                _Metric(
                  label: 'USUARIOS',
                  value: (usuariosCount ?? 0).toString(),
                  emphasize: true,
                ),
                const SizedBox(width: 18),
                _Metric(
                  label: 'SCHEMA',
                  value: tenant.schemaName.replaceFirst('tenant_', ''),
                  mono: true,
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  iconSize: 20,
                  color: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: cs.outline),
                  ),
                  onSelected: (value) {
                    if (value == 'editar') onEditar();
                    if (value == 'desactivar') onDesactivar();
                    if (value == 'activar') onActivar();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    if (activo)
                      const PopupMenuItem(
                        value: 'desactivar',
                        child: Row(
                          children: [
                            Icon(Icons.block_outlined,
                                size: 18, color: AppColors.danger),
                            SizedBox(width: 10),
                            Text('Desactivar',
                                style: TextStyle(color: AppColors.danger)),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'activar',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 18, color: AppColors.ok),
                            SizedBox(width: 10),
                            Text('Activar',
                                style: TextStyle(color: AppColors.ok)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool activo;
  const _StatusPill({required this.activo});

  @override
  Widget build(BuildContext context) {
    final bg = activo ? AppColors.okSoft : AppColors.neutralSoft;
    final fg = activo ? AppColors.ok : Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            activo ? 'ACTIVO' : 'INACTIVO',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final bool mono;
  const _Metric({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 15 : 12,
            fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
            color: emphasize ? cs.onSurface : cs.onSurfaceVariant,
            fontFamily: mono ? 'monospace' : null,
            letterSpacing: mono ? 0 : -0.2,
          ),
        ),
      ],
    );
  }
}
