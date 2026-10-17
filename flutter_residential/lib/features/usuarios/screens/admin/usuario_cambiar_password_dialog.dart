import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/exceptions/api_exception.dart';
import '../../../../core/utils/password_policy.dart';
import '../../../../shared/utils/mensaje_operacion.dart';
import '../../../../shared/widgets/password_form_field.dart';
import '../../../../shared/widgets/password_policy_indicator.dart';
import '../../models/usuario_response.dart';
import '../../providers/usuario_provider.dart';

/// El TENANT_ADMIN asigna una contraseña nueva a un usuario.
/// Misma política que crear usuario ([PasswordPolicy] ↔ PasswordPolicyValidator).
class UsuarioCambiarPasswordDialog extends StatefulWidget {
  final UsuarioResponse usuario;

  const UsuarioCambiarPasswordDialog({super.key, required this.usuario});

  @override
  State<UsuarioCambiarPasswordDialog> createState() =>
      _UsuarioCambiarPasswordDialogState();
}

class _UsuarioCambiarPasswordDialogState
    extends State<UsuarioCambiarPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final provider = context.read<UsuarioProvider>();
      final ok = await provider.cambiarPassword(
        widget.usuario.id,
        _passwordCtrl.text,
      );
      if (!mounted) return;

      if (!ok) {
        MensajeOperacion.error(
          context,
          'No se pudo cambiar la contraseña',
          provider.error,
        );
        return;
      }
      MensajeOperacion.exito(
        context,
        'Contraseña actualizada. ${widget.usuario.nombre} deberá iniciar sesión de nuevo.',
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      MensajeOperacion.error(
        context,
        'Error al cambiar la contraseña',
        ApiException.extract(e),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: cs.primaryContainer,
                      child: Icon(Icons.lock_reset, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cambiar contraseña',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.usuario.email,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _guardando ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                PasswordFormField(
                  controller: _passwordCtrl,
                  label: 'Nueva contraseña',
                  validator: PasswordPolicy.validate,
                  textInputAction: TextInputAction.next,
                ),
                // Solo se reconstruye el checklist, no todo el diálogo
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _passwordCtrl,
                  builder: (_, value, __) =>
                      PasswordPolicyIndicator(password: value.text),
                ),
                const SizedBox(height: 12),

                PasswordFormField(
                  controller: _confirmCtrl,
                  label: 'Confirmar contraseña',
                  validator: (v) =>
                      PasswordPolicy.validateConfirmacion(v, _passwordCtrl.text),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _guardar(),
                ),
                const SizedBox(height: 12),

                Text(
                  'Se cerrarán las sesiones abiertas del usuario. '
                  'Comunícale la nueva contraseña por un canal seguro.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _guardando
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.lock_reset),
                        label: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
