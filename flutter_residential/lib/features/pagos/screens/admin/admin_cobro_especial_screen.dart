import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cobros_provider.dart';
import '../../../propiedades/services/propiedad_service.dart';

class AdminCobroEspecialScreen extends StatefulWidget {
  const AdminCobroEspecialScreen({super.key});

  @override
  State<AdminCobroEspecialScreen> createState() =>
      _AdminCobroEspecialScreenState();
}

class _AdminCobroEspecialScreenState extends State<AdminCobroEspecialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  // Conceptos permitidos para cobros especiales (excluye ADMINISTRACION que es automático)
  static const _conceptos = ['MULTA', 'SANCION', 'PARQUEADERO', 'ZONA_COMUN', 'OTRO'];
  static const _etiquetasConcepto = {
    'MULTA': 'Multa',
    'SANCION': 'Sanción',
    'PARQUEADERO': 'Parqueadero',
    'ZONA_COMUN': 'Zona común',
    'OTRO': 'Otro',
  };

  String _conceptoSeleccionado = 'MULTA';
  Map<String, dynamic>? _propiedadSeleccionada;
  DateTime _fechaLimite = DateTime.now().add(const Duration(days: 15));

  List<Map<String, dynamic>> _propiedades = [];
  bool _cargandoPropiedades = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargarPropiedades();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPropiedades() async {
    try {
      final lista = await PropiedadService.listarPropiedades();
      if (mounted) setState(() => _propiedades = lista);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando propiedades: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoPropiedades = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaLimite,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Fecha límite de pago',
    );
    if (fecha != null) setState(() => _fechaLimite = fecha);
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_propiedadSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una propiedad'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      final monto = double.parse(_montoCtrl.text.replaceAll(',', '.'));
      await context.read<CobrosProvider>().crearCobroEspecial({
        'propiedadId': _propiedadSeleccionada!['id'],
        'concepto': _conceptoSeleccionado,
        'descripcion': _descripcionCtrl.text.trim(),
        'monto': monto,
        'fechaLimitePago':
            '${_fechaLimite.year}-${_fechaLimite.month.toString().padLeft(2, '0')}-${_fechaLimite.day.toString().padLeft(2, '0')}',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_etiquetasConcepto[_conceptoSeleccionado]} generada para '
              '${_propiedadSeleccionada!['pathTexto'] ?? _propiedadSeleccionada!['identificador']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Cobro especial')),
      body: _cargandoPropiedades
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Banner informativo ────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: cs.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Los cobros especiales se generan de forma individual para una propiedad específica y no están ligados a un período de facturación.',
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Tipo de cobro ─────────────────────────────────
                  Text('Tipo de cobro',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _conceptos.map((c) {
                      final seleccionado = c == _conceptoSeleccionado;
                      return ChoiceChip(
                        label: Text(_etiquetasConcepto[c]!),
                        selected: seleccionado,
                        onSelected: (_) => setState(() => _conceptoSeleccionado = c),
                        selectedColor: cs.primary,
                        labelStyle: TextStyle(
                          fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                          color: seleccionado ? cs.onPrimaryContainer : cs.onSurface,
                        ),
                        checkmarkColor:  seleccionado ? cs.onPrimaryContainer : cs.onSurface,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Propiedad ─────────────────────────────────────
                  Text('Propiedad',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: _propiedadSeleccionada,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Selecciona la propiedad',
                      prefixIcon: Icon(Icons.home_work_outlined),
                    ),
                    isExpanded: true,
                    items: _propiedades.map((p) {
                      final label = p['pathTexto'] as String? ??
                          p['identificador'] as String? ??
                          'Propiedad ${p['id']}';
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: p,
                        child: Text(label, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _propiedadSeleccionada = v),
                    validator: (_) =>
                        _propiedadSeleccionada == null ? 'Selecciona una propiedad' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Descripción ───────────────────────────────────
                  TextFormField(
                    controller: _descripcionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descripción / motivo',
                      hintText: 'Ej: Ruido fuera de horario permitido',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length < 3) {
                        return 'Ingresa una descripción de al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Monto ─────────────────────────────────────────
                  TextFormField(
                    controller: _montoCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                      if (n == null || n <= 0) return 'Ingresa un monto válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Fecha límite ──────────────────────────────────
                  Text('Fecha límite de pago',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _seleccionarFecha,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.outline),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 20, color: cs.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Text(
                            '${_fechaLimite.day.toString().padLeft(2, '0')}/'
                            '${_fechaLimite.month.toString().padLeft(2, '0')}/'
                            '${_fechaLimite.year}',
                            style: TextStyle(fontSize: 15, color: cs.onSurface),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right,
                              color: cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Botón enviar ──────────────────────────────────
                  FilledButton.icon(
                    onPressed: _enviando ? null : _enviar,
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(Icons.send_outlined, color: cs.onPrimaryContainer,),
                    label: Text(
                        'Generar cobro ${_etiquetasConcepto[_conceptoSeleccionado]!.toLowerCase()}',
                        style: TextStyle(color: cs.onPrimaryContainer)
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
