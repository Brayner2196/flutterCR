import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/votacion_model.dart';
import '../../providers/votacion_provider.dart';

class AdminCrearVotacionScreen extends StatefulWidget {
  final VotacionModel? votacionEditar;
  const AdminCrearVotacionScreen({super.key, this.votacionEditar});

  @override
  State<AdminCrearVotacionScreen> createState() => _AdminCrearVotacionScreenState();
}

class _AdminCrearVotacionScreenState extends State<AdminCrearVotacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _escalaCtrl = TextEditingController(text: '5');
  final List<TextEditingController> _opcionesCtrl = [];

  String _tipo = 'OPCION_UNICA';
  bool _mostrarVotantes = false;
  bool _permiteCambiarVoto = false;
  bool _guardando = false;

  static const _tipos = ['OPCION_UNICA', 'OPCION_MULTIPLE', 'ESCALA_NUMERICA', 'TEXTO_LIBRE'];
  static const _tiposLabel = ['Opción única', 'Opción múltiple', 'Escala numérica', 'Texto libre'];

  bool get _esEdicion => widget.votacionEditar != null;
  bool get _necesitaOpciones => _tipo == 'OPCION_UNICA' || _tipo == 'OPCION_MULTIPLE';

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final v = widget.votacionEditar!;
      _tituloCtrl.text = v.titulo;
      _descCtrl.text = v.descripcion ?? '';
      _tipo = v.tipoVotacion;
      _escalaCtrl.text = (v.escalaMax ?? 5).toString();
      _mostrarVotantes = v.mostrarVotantes;
      _permiteCambiarVoto = v.permiteCambiarVoto;
      for (final op in v.opciones) {
        _opcionesCtrl.add(TextEditingController(text: op.texto));
      }
    } else {
      _opcionesCtrl.add(TextEditingController());
      _opcionesCtrl.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _escalaCtrl.dispose();
    for (final c in _opcionesCtrl) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar votación' : 'Nueva votación'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                    labelText: 'Pregunta / Título *', border: OutlineInputBorder()),
                maxLength: 300,
                validator: (v) => (v == null || v.isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('Tipo de respuesta', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(_tipos.length, (i) => ChoiceChip(
                  label: Text(_tiposLabel[i]),
                  selected: _tipo == _tipos[i],
                  onSelected: (_) => setState(() => _tipo = _tipos[i]),
                )),
              ),
              const SizedBox(height: 16),
              if (_tipo == 'ESCALA_NUMERICA') ...[
                TextFormField(
                  controller: _escalaCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Valor máximo de la escala',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 2) return 'Mínimo 2';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              if (_necesitaOpciones) ...[
                const Text('Opciones de respuesta', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._opcionesCtrl.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: entry.value,
                          decoration: InputDecoration(
                              labelText: 'Opción ${entry.key + 1}',
                              border: const OutlineInputBorder()),
                          validator: (v) => (v == null || v.isEmpty) ? 'Escribe la opción' : null,
                        ),
                      ),
                      if (_opcionesCtrl.length > 2)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _opcionesCtrl[entry.key].dispose();
                              _opcionesCtrl.removeAt(entry.key);
                            });
                          },
                        ),
                    ],
                  ),
                )),
                TextButton.icon(
                  onPressed: () => setState(() => _opcionesCtrl.add(TextEditingController())),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar opción'),
                ),
                const SizedBox(height: 8),
              ],
              const Divider(),
              SwitchListTile(
                title: const Text('Mostrar quiénes han votado'),
                subtitle: const Text('Los residentes podrán ver la lista de votantes'),
                value: _mostrarVotantes,
                onChanged: (v) => setState(() => _mostrarVotantes = v),
              ),
              SwitchListTile(
                title: const Text('Permitir cambiar el voto'),
                subtitle: const Text('El residente puede modificar su respuesta'),
                value: _permiteCambiarVoto,
                onChanged: (v) => setState(() => _permiteCambiarVoto = v),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text(_esEdicion ? 'Guardar cambios' : 'Crear votación'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final body = <String, dynamic>{
        'titulo': _tituloCtrl.text.trim(),
        'descripcion': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'tipoVotacion': _tipo,
        'mostrarVotantes': _mostrarVotantes,
        'permiteCambiarVoto': _permiteCambiarVoto,
        if (_tipo == 'ESCALA_NUMERICA') 'escalaMax': int.tryParse(_escalaCtrl.text) ?? 5,
        if (_necesitaOpciones)
          'opciones': _opcionesCtrl.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
      };

      final provider = context.read<VotacionProvider>();
      if (_esEdicion) {
        await provider.actualizar(widget.votacionEditar!.id, body);
      } else {
        await provider.crear(body);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}
