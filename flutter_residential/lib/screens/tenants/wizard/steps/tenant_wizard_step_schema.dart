import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TenantWizardStepSchema extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController schemaCtrl;
  final String nombreConjunto;

  const TenantWizardStepSchema({
    super.key,
    required this.formKey,
    required this.schemaCtrl,
    required this.nombreConjunto,
  });

  String _sugerirSchema(String nombre) {
    return nombre
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final sugerido = _sugerirSchema(nombreConjunto);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBanner(
              icon: Icons.storage_outlined,
              color: Colors.indigo,
              texto:
                  'El schema es el identificador de la base de datos del tenant. Solo puede contener letras minúsculas, números y guiones bajos.',
            ),
            const SizedBox(height: 24),
            Text(
              'Nombre del schema (DB)',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No se puede cambiar después de creado.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: schemaCtrl,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
              ],
              decoration: InputDecoration(
                hintText: 'ej: el_prado_01',
                hintStyle: const TextStyle(fontFamily: 'monospace'),
                prefixIcon: Icon(Icons.storage_outlined, color: Colors.indigo),
                suffixIcon: sugerido.isNotEmpty
                    ? TextButton(
                        onPressed: () => schemaCtrl.text = sugerido,
                        child: const Text(
                          'Usar sugerido',
                          style: TextStyle(fontSize: 11),
                        ),
                      )
                    : null,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v.trim())) {
                  return 'Solo minúsculas, números y guiones bajos';
                }
                return null;
              },
            ),
            if (sugerido.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Sugerido: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      sugerido,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            _ReglaChip(
              icono: Icons.check_circle_outline,
              color: Colors.green,
              texto: 'Solo letras minúsculas (a-z)',
            ),
            const SizedBox(height: 8),
            _ReglaChip(
              icono: Icons.check_circle_outline,
              color: Colors.green,
              texto: 'Números (0-9) y guiones bajos (_)',
            ),
            const SizedBox(height: 8),
            _ReglaChip(
              icono: Icons.cancel_outlined,
              color: Colors.red,
              texto: 'Sin espacios, tildes ni mayúsculas',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReglaChip extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String texto;
  const _ReglaChip({required this.icono, required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          texto,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

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
