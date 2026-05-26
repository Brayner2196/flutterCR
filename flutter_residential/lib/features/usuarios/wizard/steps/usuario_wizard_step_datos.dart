import 'package:flutter/material.dart';
import '../../../../core/utils/password_policy.dart';
import '../../../../shared/widgets/password_policy_indicator.dart';

class UsuarioWizardStepDatos extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController telefonoCtrl;
  final bool verPassword;
  final VoidCallback onToggleVerPassword;

  const UsuarioWizardStepDatos({
    super.key,
    required this.formKey,
    required this.nombreCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.telefonoCtrl,
    required this.verPassword,
    required this.onToggleVerPassword,
  });

  @override
  State<UsuarioWizardStepDatos> createState() => _UsuarioWizardStepDatosState();
}

class _UsuarioWizardStepDatosState extends State<UsuarioWizardStepDatos> {
  String _passwordValue = '';

  @override
  void initState() {
    super.initState();
    _passwordValue = widget.passwordCtrl.text;
    widget.passwordCtrl.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    widget.passwordCtrl.removeListener(_onPasswordChanged);
    super.dispose();
  }

  void _onPasswordChanged() {
    if (mounted && widget.passwordCtrl.text != _passwordValue) {
      setState(() => _passwordValue = widget.passwordCtrl.text);
    }
  }

  InputDecoration _decor(
    BuildContext context,
    String label,
    IconData icon, {
    Widget? suffix,
  }) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_add_outlined, color: cs.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ingresa los datos de acceso del nuevo usuario.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nombre
            TextFormField(
              controller: widget.nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration:
                  _decor(context, 'Nombre completo', Icons.person_outline),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Email
            TextFormField(
              controller: widget.emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  _decor(context, 'Correo electrónico', Icons.email_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (!RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$')
                    .hasMatch(v.trim())) {
                  return 'Correo no válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Contraseña — validación con política completa
            TextFormField(
              controller: widget.passwordCtrl,
              obscureText: !widget.verPassword,
              decoration: _decor(
                context,
                'Contraseña',
                Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(widget.verPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: widget.onToggleVerPassword,
                ),
              ),
              validator: PasswordPolicy.validate,
            ),

            // Indicador de política en tiempo real
            PasswordPolicyIndicator(password: _passwordValue),

            const SizedBox(height: 14),

            // Teléfono
            TextFormField(
              controller: widget.telefonoCtrl,
              keyboardType: TextInputType.phone,
              decoration:
                  _decor(context, 'Teléfono (opcional)', Icons.phone_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(v.trim())) {
                  return 'Solo números, 7–15 dígitos';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Hint seguridad
            Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'La contraseña se almacena de forma cifrada.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
