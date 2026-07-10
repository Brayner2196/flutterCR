import 'package:flutter/material.dart';
import '../../core/utils/password_policy.dart';

/// Muestra un checklist en tiempo real con los requisitos de la contraseña.
/// Úsalo debajo de un [TextFormField] de contraseña y pásale el valor actual.
///
/// Ejemplo:
/// ```dart
/// PasswordPolicyIndicator(password: _passwordCtrl.text)
/// ```
class PasswordPolicyIndicator extends StatelessWidget {
  final String password;

  const PasswordPolicyIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final rules = PasswordPolicy.evaluate(password);
    final theme = Theme.of(context);

    // No mostrar nada si aún no se ha escrito nada
    if (password.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha:0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La contraseña debe:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...rules.map((rule) => _PolicyRow(rule: rule)),
          ],
        ),
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final PolicyRule rule;
  const _PolicyRow({required this.rule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = rule.passes
        ? const Color(0xFF2E7D32)   // verde Material
        : theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            rule.passes ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              rule.label,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
