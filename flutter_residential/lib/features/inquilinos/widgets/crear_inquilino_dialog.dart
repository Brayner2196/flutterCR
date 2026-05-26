import 'package:flutter/material.dart';
import '../services/inquilino_service.dart';
import '../../../features/usuarios/models/usuario_response.dart';
import '../../../core/utils/password_policy.dart';
import '../../../shared/widgets/password_policy_indicator.dart';

class CrearInquilinoDialog extends StatefulWidget {
  const CrearInquilinoDialog({super.key});

  @override
  State<CrearInquilinoDialog> createState() => _CrearInquilinoDialogState();
}

class _CrearInquilinoDialogState extends State<CrearInquilinoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  bool _verPassword = false;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final inquilino = await InquilinoService.crearInquilino(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim().toLowerCase(),
        password: _passwordCtrl.text,
        telefono: _telefonoCtrl.text.trim().isNotEmpty
            ? _telefonoCtrl.text.trim()
            : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Usuario inquilino creado'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop<UsuarioResponse>(inquilino);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrio un error: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.tertiaryContainer,
                    child: Icon(Icons.person_add_outlined,
                        color: theme.colorScheme.tertiary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agregar inquilino',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Se asignará a tu misma unidad',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nombreCtrl,
                decoration: _decor('Nombre completo', Icons.person_outline),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailCtrl,
                decoration:
                    _decor('Correo electrónico', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (!RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$')
                      .hasMatch(v.trim())) {
                    return 'Correo no válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _passwordCtrl,
                obscureText: !_verPassword,
                onChanged: (_) => setState(() {}),
                decoration: _decor('Contraseña inicial', Icons.lock_outline)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_verPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _verPassword = !_verPassword),
                  ),
                ),
                validator: PasswordPolicy.validate,
              ),
              PasswordPolicyIndicator(password: _passwordCtrl.text),
              const SizedBox(height: 12),

              TextFormField(
                controller: _telefonoCtrl,
                decoration: _decor('Teléfono (opcional)', Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(v.trim())) {
                    return 'Teléfono no válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _guardando ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _guardando ? null : _crear,
                      icon: _guardando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.person_add_outlined),
                      label: const Text('Agregar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
