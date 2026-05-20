import 'package:flutter/material.dart';
import 'package:flutter_residential/features/configuracion/models/conjunto_model.dart';
import 'package:flutter_residential/features/configuracion/services/conjunto_service.dart';
import 'package:flutter_residential/shared/theme/app_theme.dart';

class ConfigConjuntoScreen extends StatefulWidget {
  const ConfigConjuntoScreen({super.key});

  @override
  State<ConfigConjuntoScreen> createState() => _ConfigConjuntoScreenState();
}

class _ConfigConjuntoScreenState extends State<ConfigConjuntoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  ConjuntoModel? _conjunto;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final c = await ConjuntoService.obtener();
      _nombreCtrl.text = c.nombre;
      _direccionCtrl.text = c.direccion ?? '';
      setState(() { _conjunto = c; _cargando = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _cargando = false; });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);
    try {
      final actualizado = await ConjuntoService.actualizar(
        nombre: _nombreCtrl.text.trim(),
        direccion: _direccionCtrl.text.trim().isEmpty ? null : _direccionCtrl.text.trim(),
      );
      setState(() { _conjunto = actualizado; _guardando = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Cambios guardados'),
          ]),
          backgroundColor: AppColors.ok,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      setState(() => _guardando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del conjunto'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(mensaje: _error!, onRetry: _cargar)
              : _buildForm(cs, theme),
    );
  }

  Widget _buildForm(ColorScheme cs, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner con código (read-only)
            if (_conjunto != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.qr_code_rounded,
                          color: Colors.deepPurple, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Código de acceso',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.deepPurple.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                            )),
                        Text(
                          _conjunto!.codigo,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Tooltip(
                      message: 'El código no puede modificarse',
                      child: Icon(Icons.lock_outline,
                          size: 16, color: Colors.deepPurple.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Nombre
            TextFormField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre del conjunto',
                prefixIcon: const Icon(Icons.apartment_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo requerido';
                if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Dirección
            TextFormField(
              controller: _direccionCtrl,
              decoration: InputDecoration(
                labelText: 'Dirección (opcional)',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;
  const _ErrorView({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
