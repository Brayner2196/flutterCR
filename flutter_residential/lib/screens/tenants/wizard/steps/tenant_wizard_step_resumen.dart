import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'tenant_wizard_step_propiedades.dart';

class TenantWizardStepResumen extends StatelessWidget {
  final TextEditingController nombreCtrl;
  final TextEditingController codigoCtrl;
  final TextEditingController direccionCtrl;
  final TextEditingController schemaCtrl;
  final TextEditingController emailCtrl;
  final List<TipoNodoEditable> tiposPropiedad;

  const TenantWizardStepResumen({
    super.key,
    required this.nombreCtrl,
    required this.codigoCtrl,
    required this.direccionCtrl,
    required this.schemaCtrl,
    required this.emailCtrl,
    required this.tiposPropiedad,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final tiposValidos = tiposPropiedad
        .where((t) => t.nombreCtrl.text.trim().isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Banner de confirmación ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.ok.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.ok.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.okSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.ok,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Todo listo para crear!',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.ok,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Revisa los datos antes de confirmar. No podrás cambiar el schema después.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.ok.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Sección: Información básica ─────────────────────────────────
          _SeccionResumen(
            titulo: 'Información básica',
            icono: Icons.apartment_outlined,
            color: cs.primary,
            items: [
              _ItemResumen(
                label: 'Nombre',
                valor: nombreCtrl.text.trim(),
                icono: Icons.apartment_outlined,
              ),
              _ItemResumen(
                label: 'Código',
                valor: codigoCtrl.text.trim(),
                icono: Icons.tag,
                mono: true,
              ),
              if (direccionCtrl.text.trim().isNotEmpty)
                _ItemResumen(
                  label: 'Dirección',
                  valor: direccionCtrl.text.trim(),
                  icono: Icons.location_on_outlined,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Sección: Base de datos ──────────────────────────────────────
          _SeccionResumen(
            titulo: 'Base de datos',
            icono: Icons.storage_outlined,
            color: Colors.indigo,
            items: [
              _ItemResumen(
                label: 'Schema',
                valor: schemaCtrl.text.trim(),
                icono: Icons.storage_outlined,
                mono: true,
                esImportante: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Sección: Administrador ──────────────────────────────────────
          _SeccionResumen(
            titulo: 'Administrador',
            icono: Icons.manage_accounts_outlined,
            color: Colors.deepPurple,
            items: [
              _ItemResumen(
                label: 'Correo',
                valor: emailCtrl.text.trim(),
                icono: Icons.email_outlined,
              ),
              const _ItemResumen(
                label: 'Contraseña',
                valor: '••••••••',
                icono: Icons.lock_outlined,
              ),
            ],
          ),

          // ── Sección: Tipos de propiedad ─────────────────────────────────
          if (tiposValidos.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SeccionResumen(
              titulo: 'Tipos de propiedad',
              icono: Icons.home_work_outlined,
              color: Colors.teal,
              items: tiposValidos
                  .map(
                    (t) => _ItemResumen(
                      label: t.nombreCtrl.text.trim(),
                      valor: t.hijos
                              .where((h) => h.nombreCtrl.text.trim().isNotEmpty)
                              .map((h) => h.nombreCtrl.text.trim())
                              .join(', ')
                              .isNotEmpty
                          ? t.hijos
                              .where((h) => h.nombreCtrl.text.trim().isNotEmpty)
                              .map((h) => h.nombreCtrl.text.trim())
                              .join(', ')
                          : 'Sin subtipos',
                      icono: Icons.home_work_outlined,
                    ),
                  )
                  .toList(),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    'Sin tipos de propiedad configurados',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Alerta schema inmutable ─────────────────────────────────────
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.orange.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'El schema "${schemaCtrl.text.trim()}" no podrá ser cambiado una vez se cree el tenant. Verifica que sea correcto.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                      height: 1.4,
                    ),
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

// ─── Sección agrupada ─────────────────────────────────────────────────────────

class _SeccionResumen extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final List<_ItemResumen> items;

  const _SeccionResumen({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado de sección ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(icono, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // ── Items ───────────────────────────────────────────────────────
          ...items.map(
            (item) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: item,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item individual ──────────────────────────────────────────────────────────

class _ItemResumen extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final bool mono;
  final bool esImportante;

  const _ItemResumen({
    required this.label,
    required this.valor,
    required this.icono,
    this.mono = false,
    this.esImportante = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      esImportante ? FontWeight.w700 : FontWeight.w500,
                  color: esImportante
                      ? Colors.indigo
                      : cs.onSurface,
                  fontFamily: mono ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
