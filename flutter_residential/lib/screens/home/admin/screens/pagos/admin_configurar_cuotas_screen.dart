import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../models/configuracion_cuota_model.dart';
import '../../../../../models/tipo_propiedad_nodo.dart';
import '../../../../../services/cuota_service.dart';

typedef _Preset = ({String label, String tipoNombre, double monto, int desde, int hasta});

class AdminConfigurarCuotasScreen extends StatefulWidget {
  const AdminConfigurarCuotasScreen({super.key});

  @override
  State<AdminConfigurarCuotasScreen> createState() =>
      _AdminConfigurarCuotasScreenState();
}

class _AdminConfigurarCuotasScreenState
    extends State<AdminConfigurarCuotasScreen> {
  static const List<_Preset> _presets = [
    (label: 'Apto Nros 1–10', tipoNombre: 'apartamento', monto: 194014.0, desde: 1, hasta: 10),
    (label: 'Apto Nros 11–18', tipoNombre: 'apartamento', monto: 199696.0, desde: 11, hasta: 18),
    (label: 'Parqueadero Nº 41', tipoNombre: 'parqueadero', monto: 34922.0, desde: 41, hasta: 41),
    (label: 'Parqueaderos Nros 42–46', tipoNombre: 'parqueadero', monto: 40604.0, desde: 42, hasta: 46),
  ];

  final _form = GlobalKey<FormState>();
  final _montoCtrl = TextEditingController();
  final _desdeCtrl = TextEditingController();
  final _hastaCtrl = TextEditingController();
  String _periodicidad = 'MENSUAL';
  int? _tipoPropiedadId;
  DateTime _fechaVigencia = DateTime.now();
  bool _usarRango = false;
  bool _guardando = false;
  bool _cargando = true;
  List<TipoPropiedadNodo> _tiposFlat = [];
  List<ConfiguracionCuotaModel> _cuotas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _desdeCtrl.dispose();
    _hastaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final resT = await ApiClient.get(ApiConstants.tiposPropiedad);
      final listJson = jsonDecode(resT.body) as List;
      final nodos = listJson.map((e) => TipoPropiedadNodo.fromJson(e)).toList();
      final flat = <TipoPropiedadNodo>[];
      void flatten(TipoPropiedadNodo n) {
        flat.add(n);
        for (final h in n.hijos) flatten(h);
      }
      for (final n in nodos) flatten(n);

      final cuotas = await CuotaService.listar();
      if (mounted) {
        setState(() {
          _tiposFlat = flat;
          _cuotas = cuotas;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _aplicarPreset(_Preset preset) {
    final tipoId = _tiposFlat
        .where((t) => t.nombre.toLowerCase().contains(preset.tipoNombre))
        .map((t) => t.id)
        .firstOrNull;
    setState(() {
      _tipoPropiedadId = tipoId;
      _montoCtrl.text = preset.monto.toStringAsFixed(0);
      _periodicidad = 'MENSUAL';
      _usarRango = true;
      _desdeCtrl.text = preset.desde.toString();
      _hastaCtrl.text = preset.hasta.toString();
    });
  }

  void _resetForm() {
    _montoCtrl.clear();
    _desdeCtrl.clear();
    _hastaCtrl.clear();
    setState(() {
      _tipoPropiedadId = null;
      _periodicidad = 'MENSUAL';
      _usarRango = false;
      _fechaVigencia = DateTime.now();
    });
  }

  Future<void> _desactivar(int id) async {
    try {
      await CuotaService.desactivar(id);
      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cuota desactivada'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    if (_tipoPropiedadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona un tipo de propiedad'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _guardando = true);
    try {
      final fechaStr =
          '${_fechaVigencia.year}-${_fechaVigencia.month.toString().padLeft(2, '0')}-${_fechaVigencia.day.toString().padLeft(2, '0')}';
      final body = <String, dynamic>{
        'tipoPropiedadId': _tipoPropiedadId,
        'monto': double.parse(_montoCtrl.text),
        'periodicidad': _periodicidad,
        'fechaVigenciaDesde': fechaStr,
      };
      if (_usarRango) {
        body['numeroDesde'] = int.parse(_desdeCtrl.text);
        body['numeroHasta'] = int.parse(_hastaCtrl.text);
      }
      await CuotaService.crear(body);
      _resetForm();
      await _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Configuración guardada correctamente'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _nombreTipo(int id) => _tiposFlat
      .firstWhere((t) => t.id == id,
          orElse: () => TipoPropiedadNodo(id: id, nombre: '#$id'))
      .nombre;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurar Cuotas')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_cuotas.isNotEmpty) ..._buildCuotasActivas(),
                  Card(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
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
                  Text('Tarifas rápidas',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presets
                        .map((p) => OutlinedButton.icon(
                              onPressed: () => _aplicarPreset(p),
                              icon: const Icon(Icons.bolt, size: 16),
                              label: Text(p.label,
                                  style: const TextStyle(fontSize: 12)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Nueva configuración',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _tipoPropiedadId,
                    decoration: const InputDecoration(
                        labelText: 'Tipo de propiedad',
                        border: OutlineInputBorder()),
                    items: _tiposFlat
                        .map((t) => DropdownMenuItem(
                            value: t.id, child: Text(t.nombre)))
                        .toList(),
                    onChanged: (v) => setState(() => _tipoPropiedadId = v),
                  ),
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
                  const SizedBox(height: 4),
                  SwitchListTile(
                    value: _usarRango,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aplicar por rango de número'),
                    onChanged: (v) => setState(() {
                      _usarRango = v;
                      if (!v) {
                        _desdeCtrl.clear();
                        _hastaCtrl.clear();
                      }
                    }),
                  ),
                  if (_usarRango) ...[  
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _desdeCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Número desde',
                                border: OutlineInputBorder()),
                            validator: (v) {
                              if (!_usarRango) return null;
                              if (v == null || v.isEmpty) return 'Requerido';
                              if (int.tryParse(v) == null) return 'Entero';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _hastaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Número hasta',
                                border: OutlineInputBorder()),
                            validator: (v) {
                              if (!_usarRango) return null;
                              if (v == null || v.isEmpty) return 'Requerido';
                              final hasta = int.tryParse(v);
                              if (hasta == null) return 'Entero';
                              final desde = int.tryParse(_desdeCtrl.text) ?? 0;
                              if (hasta < desde) return '≥ Desde';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<String>(
                    value: _periodicidad,
                    decoration: const InputDecoration(
                        labelText: 'Periodicidad',
                        border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: 'MENSUAL', child: Text('Mensual')),
                      DropdownMenuItem(
                          value: 'TRIMESTRAL', child: Text('Trimestral')),
                      DropdownMenuItem(value: 'ANUAL', child: Text('Anual')),
                    ],
                    onChanged: (v) => setState(() => _periodicidad = v!),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _fechaVigencia,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _fechaVigencia = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Vigencia desde',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today)),
                      child: Text(
                          '${_fechaVigencia.day.toString().padLeft(2, '0')}/${_fechaVigencia.month.toString().padLeft(2, '0')}/${_fechaVigencia.year}'),
                    ),
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

  List<Widget> _buildCuotasActivas() {
    return [
      Text('Configuraciones activas',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ..._cuotas.map((c) {
        final rangoStr = c.numeroDesde != null
            ? (c.numeroDesde == c.numeroHasta
                ? 'Nº ${c.numeroDesde} · '
                : 'Nros ${c.numeroDesde}–${c.numeroHasta} · ')
            : '';
        return Card(
          child: ListTile(
            title: Text(c.tipoPropiedadId != null
                ? _nombreTipo(c.tipoPropiedadId!)
                : 'Propiedad #${c.propiedadId}'),
            subtitle: Text(
                '$rangoStr\$${c.monto.toStringAsFixed(0)} · ${c.periodicidad}'),
            trailing: IconButton(
              icon:
                  const Icon(Icons.remove_circle_outline, color: Colors.red),
              tooltip: 'Desactivar',
              onPressed: () => _desactivar(c.id),
            ),
          ),
        );
      }),
      const Divider(height: 32),
    ];
  }
}
