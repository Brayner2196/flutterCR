import 'package:flutter/material.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';
import 'usuario_wizard_step_rol.dart';

class UsuarioWizardStepResumen extends StatelessWidget {
  final String rol;
  final String nombre;
  final String email;
  final String? telefono;
  final List<String> pathLabels;

  const UsuarioWizardStepResumen({
    super.key,
    required this.rol,
    required this.nombre,
    required this.email,
    this.telefono,
    required this.pathLabels,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final config = kRolesConfig[rol];
    final tienePropiedad = pathLabels.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Banner de confirmación ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.ok.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.ok.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.ok.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: AppColors.ok, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revisa antes de confirmar',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.ok,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Se enviará un correo con sus credenciales de acceso.',
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
          const SizedBox(height: 20),

          // ── Card de rol ────────────────────────────────────────────────
          if (config != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: config.color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: config.color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: config.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        Icon(config.icono, color: config.color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.etiqueta,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: config.color,
                        ),
                      ),
                      Text(
                        config.descripcion,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: config.color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // ── Sección: Datos personales ──────────────────────────────────
          _SeccionResumen(
            titulo: 'Datos personales',
            icono: Icons.person_outline,
            color: cs.primary,
            items: [
              _ItemResumen(
                label: 'Nombre',
                valor: nombre.isNotEmpty ? nombre : '—',
                icono: Icons.person_outline,
              ),
              _ItemResumen(
                label: 'Correo electrónico',
                valor: email.isNotEmpty ? email : '—',
                icono: Icons.email_outlined,
              ),
              const _ItemResumen(
                label: 'Contraseña',
                valor: '••••••••',
                icono: Icons.lock_outlined,
              ),
              if (telefono != null && telefono!.isNotEmpty)
                _ItemResumen(
                  label: 'Teléfono',
                  valor: telefono!,
                  icono: Icons.phone_outlined,
                ),
            ],
          ),

          // ── Sección: Propiedad ─────────────────────────────────────────
          if (tienePropiedad) ...[
            const SizedBox(height: 16),
            _SeccionResumen(
              titulo: 'Unidad asignada',
              icono: Icons.home_work_outlined,
              color: Colors.teal,
              items: [
                _ItemResumenPath(labels: pathLabels),
              ],
            ),
          ],
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
  final List<Widget> items;

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
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(icono, size: 15, color: color),
                const SizedBox(width: 8),
                Text(
                  titulo.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: item,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item de dato ─────────────────────────────────────────────────────────────

class _ItemResumen extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;

  const _ItemResumen({
    required this.label,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

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
                  letterSpacing: 0.3,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Item de path de propiedad ────────────────────────────────────────────────

class _ItemResumenPath extends StatelessWidget {
  final List<String> labels;

  const _ItemResumenPath({required this.labels});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.route_outlined, size: 16, color: cs.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ruta de la unidad',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (int i = 0; i < labels.length; i++) ...[
                    if (i > 0)
                      Icon(Icons.chevron_right,
                          size: 16, color: cs.onSurfaceVariant),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.teal.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade700,
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
    );
  }
}
