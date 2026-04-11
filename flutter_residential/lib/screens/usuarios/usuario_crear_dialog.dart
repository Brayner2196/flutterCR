import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../../providers/usuario_provider.dart';

class UsuarioCrearDialog extends StatefulWidget {
  const UsuarioCrearDialog({super.key});

  @override
  State<UsuarioCrearDialog> createState() => _UsuarioCrearDialogState();
}

class _UsuarioCrearDialogState extends State<UsuarioCrearDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _aptoCtrl = TextEditingController();
  final _torreCtrl = TextEditingController();

  String _rol = 'RESIDENTE';
  bool _verPassword = false;
  bool _guardando = false;

  static const _roles = [
    'RESIDENTE',
    'TENANT_ADMIN',
    'RESIDENTE_PENDIENTE',
    'VIGILANTE',
    'PORTERO',
    'PISCINERO',
    'CONTADOR',
  ];

  static const _etiquetasRol = {
    'RESIDENTE': 'Residente',
    'TENANT_ADMIN': 'Administrador',
    'RESIDENTE_PENDIENTE': 'Residente Pendiente',
    'VIGILANTE': 'Vigilante',
    'PORTERO': 'Portero',
    'PISCINERO': 'Piscinero',
    'CONTADOR': 'Contador',
  };

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _telefonoCtrl.dispose();
    _aptoCtrl.dispose();
    _torreCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      await context.read<UsuarioProvider>().crear({
        'nombre': _nombreCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'rol': _rol,
        if (_torreCtrl.text.trim().isNotEmpty) 'torre': _torreCtrl.text.trim(),
        if (_aptoCtrl.text.trim().isNotEmpty) 'apto': _aptoCtrl.text.trim(),
        if (_telefonoCtrl.text.trim().isNotEmpty)
          'telefono': _telefonoCtrl.text.trim(),
      });
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: const Text('Usuario creado'),
        description:
            Text('${_nombreCtrl.text.trim()} fue creado correctamente.'),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: true,
        closeOnClick: true,
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: const Text('Error al crear usuario'),
        description: Text(e.toString().replaceFirst('Exception: ', '')),
        alignment: Alignment.topRight,
        autoCloseDuration: const Duration(seconds: 4),
        showProgressBar: true,
        closeOnClick: true,
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
              // ── Encabezado
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.person_add_outlined,
                        color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nuevo usuario',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Información de acceso
              _label(theme, 'Información de acceso'),
              const SizedBox(height: 8),

              TextFormField(
                controller: _nombreCtrl,
                decoration: _decor('Nombre completo', Icons.person_outline),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo requerido'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailCtrl,
                decoration:
                    _decor('Correo electrónico', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  if (!RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-z]{2,}$')
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
                decoration: _decor('Contraseña', Icons.lock_outline).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_verPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _verPassword = !_verPassword),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _rol,
                decoration: _decor('Rol', Icons.badge_outlined),
                items: _roles
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(_etiquetasRol[r] ?? r),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _rol = v!),
                validator: (v) =>
                    v == null ? 'Selecciona un rol' : null,
              ),

              const SizedBox(height: 20),

              // ── Residencia (opcional)
              _label(theme, 'Residencia (opcional)'),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _torreCtrl,
                      decoration:
                          _decor('Torre', Icons.apartment_outlined),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _aptoCtrl,
                      decoration: _decor(
                          'Apartamento', Icons.door_front_door_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _telefonoCtrl,
                decoration: _decor('Teléfono', Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // ── Botones
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
                      onPressed: _guardando ? null : _crear,
                      icon: _guardando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.person_add_outlined),
                      label: const Text('Crear'),
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

  Widget _label(ThemeData theme, String titulo) {
    return Text(
      titulo,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
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
