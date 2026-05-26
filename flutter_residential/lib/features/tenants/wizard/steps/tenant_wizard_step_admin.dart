import 'package:flutter/material.dart';
import '../../../../core/utils/password_policy.dart';
import '../../../../shared/widgets/password_policy_indicator.dart';

class TenantWizardStepAdmin extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;

  const TenantWizardStepAdmin({
    super.key,
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
  });

  @override
  State<TenantWizardStepAdmin> createState() => _TenantWizardStepAdminState();
}

class _TenantWizardStepAdminState extends State<TenantWizardStepAdmin> {
  bool _verPassword = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBanner(
              icon: Icons.manage_accounts_outlined,
              color: Colors.deepPurple,
              texto:
                  'Estas credenciales serán del administrador principal del conjunto. Podrán ser cambiadas después desde el panel de usuarios.',
            ),
            const SizedBox(height: 24),
            Text(
              'Correo del administrador',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'admin@conjunto.com',
                prefixIcon:
                    Icon(Icons.email_outlined, color: Colors.deepPurple),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                  return 'Ingresa un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Contraseña inicial',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'El admin puede cambiarla al ingresar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.passwordCtrl,
              obscureText: !_verPassword,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: Icon(Icons.lock_outlined, color: Colors.deepPurple),
                suffixIcon: IconButton(
                  icon: Icon(
                    _verPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () => setState(() => _verPassword = !_verPassword),
                ),
              ),
              validator: PasswordPolicy.validate,
            ),
            PasswordPolicyIndicator(password: widget.passwordCtrl.text),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'El administrador recibirá acceso completo para gestionar usuarios, cobros, reservas y PQRs del conjunto.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String texto;
  const _InfoBanner({required this.icon, required this.color, required this.texto});

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
