import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _aptoCtrl = TextEditingController();
  final _torreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _cargando = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _codigoCtrl.dispose();
    _aptoCtrl.dispose();
    _torreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      final mensaje = await AuthService.registro(
        nombre: _nombreCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        codigoConjunto: _codigoCtrl.text.trim(),
        apto: _aptoCtrl.text.trim().isEmpty ? null : _aptoCtrl.text.trim(),
        torre: _torreCtrl.text.trim().isEmpty ? null : _torreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
      );

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Solicitud enviada'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // cierra diálogo
                Navigator.of(context).pop(); // vuelve al login
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de registro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ingresa tus datos y el código de tu conjunto.\nUn administrador aprobará tu acceso.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 16),
                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@')) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Contraseña
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Contraseña *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                 const SizedBox(height: 16),

                // Código del conjunto
                TextFormField(
                  controller: _codigoCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Código del conjunto *',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                    hintText: 'Ej: EL-PRADO-01',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa el código del conjunto' : null,
                ),
                const SizedBox(height: 16),

                // Torre (opcional)
                TextFormField(
                  controller: _torreCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Torre (opcional)',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Apartamento (opcional)
                TextFormField(
                  controller: _aptoCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Apartamento (opcional)',
                    prefixIcon: Icon(Icons.door_front_door_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                // Teléfono (opcional)
                TextFormField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _cargando ? null : _registrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enviar solicitud', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}