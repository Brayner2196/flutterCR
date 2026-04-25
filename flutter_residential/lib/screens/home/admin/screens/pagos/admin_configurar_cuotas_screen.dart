import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../models/configuracion_cuota_model.dart';
import '../../../../../models/tipo_propiedad_nodo.dart';
import '../../../../../services/cuota_service.dart';

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
  int? _tipoPropiedadId;
  DateTime _fechaVigencia = DateTime.now();
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
      await CuotaService.crear({
        'tipoPropiedadId': _tipoPropiedadId,
        'monto': double.parse(_montoCtrl.text),
        'periodicidad': _periodicidad,
        'fechaVigenciaDesde': fechaStr,
      });
      _montoCtrl.clear();
      setState(() => _tipoPropiedadId = null);
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
                          value: 'TRIMESTRAL', child: Text('Trimestral')),
                      DropdownMenuItem(
                          value: 'ANUAL', child: Text('Anual')),
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
      ..._cuotas.map((c) => Card(
            child: ListTile(
              title: Text(c.tipoPropiedadId != null
                  ? _nombreTipo(c.tipoPropiedadId!)
                  : 'Propiedad #${c.propiedadId}'),
              subtitle:
                  Text('\$${c.monto.toStringAsFixed(2)} · ${c.periodicidad}'),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.red),
                tooltip: 'Desactivar',
                onPressed: () => _desactivar(c.id),
              ),
            ),
          )),
      const Divider(height: 32),
    ];
  }
}
