import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/usuario_response.dart';
import '../../../../../providers/usuario_provider.dart';

class UsuarioEditarDialog extends StatefulWidget {
  final UsuarioResponse usuario;

  const UsuarioEditarDialog({super.key, required this.usuario});

  @override
  State<UsuarioEditarDialog> createState() => _UsuarioEditarDialogState();
}

class _UsuarioEditarDialogState extends State<UsuarioEditarDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _correoCtrl;

  late String _rol;
  late String _estado;
  bool _guardando = false;

  static const _roles = ['TENANT_ADMIN','RESIDENTE', 'PISCINERO'];
  static const _estados = ['PENDIENTE', 'ACTIVO', 'INACTIVO'];

  static const _etiquetasRol = {
    'TENANT_ADMIN': 'Administrador',
    'RESIDENTE': 'Residente',
    'PISCINERO': 'Piscinero',
  };

  static const _etiquetasEstado = {
    'ACTIVO': 'Activo',
    'INACTIVO': 'Inactivo',
  };

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombreCtrl = TextEditingController(text: u.nombre);
    _telefonoCtrl = TextEditingController(text: u.telefono ?? '');
    _correoCtrl = TextEditingController(text: u.email);
    _rol = _roles.contains(u.rol) ? u.rol : _roles.first;
    _estado = _estados.contains(u.estado) ? u.estado : _estados.first;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      await context.read<UsuarioProvider>().actualizar(widget.usuario.id, {
        'nombre': _nombreCtrl.text.trim(),
        'rol': _rol,
        'estado': _estado,
        if (_telefonoCtrl.text.trim().isNotEmpty)
          'telefono': _telefonoCtrl.text.trim(),
        if (_correoCtrl.text.trim().isNotEmpty) 'email': _correoCtrl.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
              // Encabezado
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      widget.usuario.nombre.isNotEmpty
                          ? widget.usuario.nombre[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar usuario',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
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

              // Sección: Información general
              _seccionLabel(theme, 'Información general'),
              const SizedBox(height: 8),

              TextFormField(
                controller: _nombreCtrl,
                decoration: _inputDecoration('Nombre completo', Icons.person_outline),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),

              _DropdownField<String>(
                value: _rol,
                items: _roles,
                label: 'Rol',
                icon: Icons.badge_outlined,
                etiqueta: (v) => _etiquetasRol[v] ?? v,
                onChanged: (v) => setState(() => _rol = v!),
              ),
              const SizedBox(height: 12),

              _DropdownField<String>(
                value: _estado,
                items: _estados,
                label: 'Estado',
                icon: Icons.toggle_on_outlined,
                etiqueta: (v) => _etiquetasEstado[v] ?? v,
                onChanged: (v) => setState(() => _estado = v!),
              ),

              const SizedBox(height: 20),

              // Sección: Residencia
              _seccionLabel(theme, 'Datos de contacto'),
              const SizedBox(height: 8),

              TextFormField(
                      controller: _correoCtrl,
                      decoration: _inputDecoration('Correo electrónico', Icons.email_outlined),
                    ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _telefonoCtrl,
                decoration: _inputDecoration('Teléfono', Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _guardando ? null : () => Navigator.of(context).pop(),
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
                          : const Icon(Icons.save_outlined),
                      label: const Text('Guardar'),
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

  Widget _seccionLabel(ThemeData theme, String titulo) {
    return Text(
      titulo,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String label;
  final IconData icon;
  final String Function(T) etiqueta;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.label,
    required this.icon,
    required this.etiqueta,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(etiqueta(e))))
          .toList(),
      onChanged: onChanged,
    );
  }
}
