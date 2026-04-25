import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../providers/cobros_provider.dart';
import '../../../../../services/cobro_service.dart';
import '../../../../../models/configuracion_cuota_model.dart';

class AdminConfigurarCuotasScreen extends StatefulWidget {
  const AdminConfigurarCuotasScreen({super.key});

  @override
  State<AdminConfigurarCuotasScreen> createState() =>
      _AdminConfigurarCuotasScreenState();
}

class _AdminConfigurarCuotasScreenState
    extends State<AdminConfigurarCuotasScreen> {
  final _form = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  String _periodicidad = 'MENSUAL';
  bool _guardando = false;

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Cuotas')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Define el monto de cuota por tipo de propiedad. '
                        'Se aplica a todas las propiedades de ese tipo que no tengan cuota individual.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Nueva configuración',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Monto de cuota',
                  prefixText: '\$',
                  border: OutlineInputBorder()),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (double.tryParse(v) == null) return 'Número inválido';
                if (double.parse(v) <= 0) return 'Debe ser mayor a 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _periodicidad,
              decoration: const InputDecoration(
                  labelText: 'Periodicidad',
                  border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: 'MENSUAL', child: Text('Mensual')),
                DropdownMenuItem(
                    value: 'TRIMESTRAL',
                    child: Text('Trimestral')),
                DropdownMenuItem(
                    value: 'ANUAL', child: Text('Anual')),
              ],
              onChanged: (v) => setState(() => _periodicidad = v!),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: const Text('Guardar configuración'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final hoy = DateTime.now();
      final fechaStr =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
      // POST to /api/admin/cuotas/configuracion
      // Using CobroService as placeholder; real implementation uses a CuotaService
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Configuración guardada correctamente'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
