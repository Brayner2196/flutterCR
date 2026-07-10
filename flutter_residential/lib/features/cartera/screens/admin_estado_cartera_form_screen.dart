import 'package:flutter/material.dart';
import '../models/estado_cartera_config_model.dart';
import '../services/cartera_config_service.dart';
import '../utils/cartera_labels.dart';

/// Editor de un estado de cartera: datos, reglas (con condiciones) y restricciones.
class AdminEstadoCarteraFormScreen extends StatefulWidget {
  final EstadoCarteraConfig? estado; // null = nuevo

  const AdminEstadoCarteraFormScreen({super.key, this.estado});

  @override
  State<AdminEstadoCarteraFormScreen> createState() => _AdminEstadoCarteraFormScreenState();
}

class _AdminEstadoCarteraFormScreenState extends State<AdminEstadoCarteraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _severidadCtrl = TextEditingController(text: '0');

  String? _color = CarteraLabels.coloresSugeridos.first;
  bool _esPositivo = false;
  bool _activo = true;
  bool _guardando = false;

  late List<ReglaCartera> _reglas;
  late List<RestriccionCartera> _restricciones;

  bool get _esNuevo => widget.estado == null;

  @override
  void initState() {
    super.initState();
    final e = widget.estado;
    if (e != null) {
      _nombreCtrl.text = e.nombre;
      _codigoCtrl.text = e.codigo;
      _descCtrl.text = e.descripcion ?? '';
      _severidadCtrl.text = e.severidad.toString();
      _color = e.color ?? CarteraLabels.coloresSugeridos.first;
      _esPositivo = e.esPositivo;
      _activo = e.activo;
      _reglas = e.reglas
          .map((r) => ReglaCartera(
                id: r.id,
                nombre: r.nombre,
                operadorLogico: r.operadorLogico,
                orden: r.orden,
                condiciones: r.condiciones
                    .map((c) => CondicionCartera(campo: c.campo, operador: c.operador, valor: c.valor))
                    .toList(),
              ))
          .toList();
      _restricciones = e.restricciones
          .map((x) => RestriccionCartera(accion: x.accion, mensaje: x.mensaje))
          .toList();
    } else {
      _reglas = [];
      _restricciones = [];
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _descCtrl.dispose();
    _severidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final estado = EstadoCarteraConfig(
      id: widget.estado?.id,
      codigo: _codigoCtrl.text.trim().toUpperCase(),
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      severidad: int.tryParse(_severidadCtrl.text) ?? 0,
      color: _color,
      esPositivo: _esPositivo,
      activo: _activo,
      reglas: _reglas,
      restricciones: _restricciones,
    );

    setState(() => _guardando = true);
    try {
      if (_esNuevo) {
        await CarteraConfigService.crear(estado);
      } else {
        await CarteraConfigService.actualizar(widget.estado!.id!, estado);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_esNuevo ? 'Nuevo estado' : 'Editar estado')),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
        child: FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_esNuevo ? 'Crear estado' : 'Guardar cambios'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _seccion('Datos del estado'),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codigoCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código',
                hintText: 'MORA, COBRO_PREJURIDICO…',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _severidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Severidad',
                helperText: 'Mayor = más grave. Gana el más severo cuyas reglas se cumplan.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: CarteraLabels.coloresSugeridos.map((hex) {
                final c = CarteraLabels.colorDeHex(hex);
                final sel = _color == hex;
                return GestureDetector(
                  onTap: () => setState(() => _color = hex),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: sel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Es el estado "al día"'),
              subtitle: const Text('El estado base positivo, sin reglas ni restricciones'),
              value: _esPositivo,
              onChanged: (v) => setState(() => _esPositivo = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activo'),
              value: _activo,
              onChanged: (v) => setState(() => _activo = v),
            ),

            if (!_esPositivo) ...[
              const SizedBox(height: 8),
              _seccionConAccion('Reglas de entrada', 'Añadir regla', () {
                setState(() => _reglas.add(ReglaCartera(nombre: 'Nueva regla')));
              }),
              if (_reglas.isEmpty)
                _hint('Sin reglas: este estado nunca se asignará automáticamente.'),
              ..._reglas.asMap().entries.map((e) => _ReglaEditor(
                    key: ValueKey('regla_${e.key}_${e.value.id}'),
                    regla: e.value,
                    onCambio: () => setState(() {}),
                    onEliminar: () => setState(() => _reglas.removeAt(e.key)),
                  )),

              const SizedBox(height: 16),
              _seccion('Restricciones'),
              _hint('Marca qué acciones se bloquean cuando la propiedad está en este estado.'),
              ...CarteraLabels.acciones.entries.map((entry) => _restriccionTile(entry.key, entry.value)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Restricciones ────────────────────────────────────────────────────────
  Widget _restriccionTile(String accion, String label) {
    final idx = _restricciones.indexWhere((r) => r.accion == accion);
    final activa = idx >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(label),
          value: activa,
          onChanged: (v) => setState(() {
            if (v == true) {
              _restricciones.add(RestriccionCartera(accion: accion));
            } else {
              _restricciones.removeWhere((r) => r.accion == accion);
            }
          }),
        ),
        if (activa)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: TextFormField(
              initialValue: _restricciones[idx].mensaje,
              decoration: const InputDecoration(
                labelText: 'Mensaje (opcional)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _restricciones[idx].mensaje = v,
            ),
          ),
      ],
    );
  }

  // ── Helpers de UI ────────────────────────────────────────────────────────
  Widget _seccion(String t) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(t.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6,
                color: Theme.of(context).colorScheme.primary)),
      );

  Widget _seccionConAccion(String t, String accion, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(t.toUpperCase(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6,
                      color: Theme.of(context).colorScheme.primary)),
            ),
            TextButton.icon(onPressed: onTap, icon: const Icon(Icons.add, size: 18), label: Text(accion)),
          ],
        ),
      );

  Widget _hint(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

// ─── Editor de una regla con sus condiciones ───────────────────────────────
class _ReglaEditor extends StatefulWidget {
  final ReglaCartera regla;
  final VoidCallback onCambio;
  final VoidCallback onEliminar;

  const _ReglaEditor({super.key, required this.regla, required this.onCambio, required this.onEliminar});

  @override
  State<_ReglaEditor> createState() => _ReglaEditorState();
}

class _ReglaEditorState extends State<_ReglaEditor> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = widget.regla;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: TextFormField(
                initialValue: r.nombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la regla', isDense: true, border: OutlineInputBorder()),
                onChanged: (v) => r.nombre = v,
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error),
              onPressed: widget.onEliminar,
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Text('Combinar condiciones: ', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: r.operadorLogico,
              items: CarteraLabels.operadoresLogicos.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => r.operadorLogico = v ?? 'AND'),
            ),
          ]),
          const Divider(),
          ...r.condiciones.asMap().entries.map((e) => _condicionRow(e.key, e.value)),
          TextButton.icon(
            onPressed: () => setState(() => r.condiciones.add(
                CondicionCartera(campo: 'DIAS_VENCIDO_MAX', operador: 'MAYOR_IGUAL', valor: 0))),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Añadir condición'),
          ),
        ],
      ),
    );
  }

  Widget _condicionRow(int i, CondicionCartera c) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<String>(
              initialValue: c.campo,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              items: CarteraLabels.campos.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => c.campo = v ?? c.campo),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: c.operador,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
              items: CarteraLabels.operadores.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => c.operador = v ?? c.operador),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: c.valor == c.valor.roundToDouble() ? c.valor.toInt().toString() : c.valor.toString(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'Valor'),
              onChanged: (v) => c.valor = double.tryParse(v) ?? 0,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: cs.error),
            onPressed: () => setState(() => widget.regla.condiciones.removeAt(i)),
          ),
        ],
      ),
    );
  }
}
