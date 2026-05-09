import 'package:flutter/material.dart';

class TenantWizardStepBasico extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreCtrl;
  final TextEditingController codigoCtrl;
  final TextEditingController direccionCtrl;

  const TenantWizardStepBasico({
    super.key,
    required this.formKey,
    required this.nombreCtrl,
    required this.codigoCtrl,
    required this.direccionCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBanner(
              icon: Icons.apartment_outlined,
              color: cs.primary,
              texto:
                  'Ingresa el nombre oficial y el código con el que identificarás este conjunto en el sistema.',
            ),
            const SizedBox(height: 24),
            Text(
              'Nombre del conjunto',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Ej: Conjunto Residencial El Prado',
                prefixIcon: Icon(Icons.apartment_outlined, color: cs.primary),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 20),
            Text(
              'Código de referencia',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Un identificador corto y único para el conjunto.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: codigoCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Ej: EL-PRADO-01',
                prefixIcon: Icon(Icons.tag, color: cs.primary),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 20),
            Text(
              'Dirección (opcional)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: direccionCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ej: Cra 15 # 80-20, Bogotá',
                prefixIcon: Icon(Icons.location_on_outlined, color: cs.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Banner informativo reutilizable ─────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String texto;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
