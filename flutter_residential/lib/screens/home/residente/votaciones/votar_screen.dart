import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/votacion_model.dart';
import '../../../../providers/votacion_provider.dart';

class VotarScreen extends StatefulWidget {
  final VotacionModel votacion;
  const VotarScreen({super.key, required this.votacion});

  @override
  State<VotarScreen> createState() => _VotarScreenState();
}

class _VotarScreenState extends State<VotarScreen> {
  late VotacionModel _votacion;
  int? _opcionSeleccionada;              // OPCION_UNICA
  final Set<int> _opcionesSeleccionadas = {}; // OPCION_MULTIPLE
  int? _valorEscala;
  final _textoCtrl = TextEditingController();
  bool _enviando = false;
  bool _modoLectura = false; // si ya votó y no puede cambiar

  @override
  void initState() {
    super.initState();
    _votacion = widget.votacion;
    _modoLectura = _votacion.yaVote && !_votacion.permiteCambiarVoto;
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_modoLectura ? 'Resultados' : 'Participar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_votacion.titulo,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_votacion.descripcion != null) ...[
              const SizedBox(height: 6),
              Text(_votacion.descripcion!,
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 8),
            Text('${_votacion.totalVotantes} personas han votado',
                style: TextStyle(fontSize: 12, color: cs.outline)),
            const Divider(height: 28),

            // Formulario / resultados según tipo
            if (_votacion.tipoVotacion == 'OPCION_UNICA')
              _buildOpcionUnica(cs),
            if (_votacion.tipoVotacion == 'OPCION_MULTIPLE')
              _buildOpcionMultiple(cs),
            if (_votacion.tipoVotacion == 'ESCALA_NUMERICA')
              _buildEscala(cs),
            if (_votacion.tipoVotacion == 'TEXTO_LIBRE')
              _buildTextoLibre(),

            // Lista de votantes (si está configurado)
            if (_votacion.mostrarVotantes &&
                _votacion.votantes != null &&
                _votacion.votantes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Quiénes han votado',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              ..._votacion.votantes!.map((v) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                          v.residenteNombre.isNotEmpty
                              ? v.residenteNombre[0].toUpperCase()
                              : '?',
                          style: TextStyle(color: cs.onPrimaryContainer)),
                    ),
                    title: Text(v.residenteNombre),
                  )),
            ],

            if (!_modoLectura) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _enviando ? null : _votar,
                  icon: _enviando
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.how_to_vote_outlined),
                  label: Text(_votacion.yaVote ? 'Cambiar mi voto' : 'Enviar voto'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionUnica(ColorScheme cs) {
    return Column(
      children: _votacion.opciones.map((op) {
        final selected = _opcionSeleccionada == op.id;
        return RadioListTile<int>(
          value: op.id,
          groupValue: _opcionSeleccionada,
          onChanged: _modoLectura ? null : (v) => setState(() => _opcionSeleccionada = v),
          title: Row(
            children: [
              Expanded(child: Text(op.texto)),
              if (_votacion.totalVotantes > 0)
                Text('${op.totalVotos}', style: TextStyle(
                  color: selected ? cs.primary : cs.outline,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                )),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOpcionMultiple(ColorScheme cs) {
    return Column(
      children: _votacion.opciones.map((op) {
        return CheckboxListTile(
          value: _opcionesSeleccionadas.contains(op.id),
          onChanged: _modoLectura
              ? null
              : (v) => setState(() {
                    if (v == true) {
                      _opcionesSeleccionadas.add(op.id);
                    } else {
                      _opcionesSeleccionadas.remove(op.id);
                    }
                  }),
          title: Row(
            children: [
              Expanded(child: Text(op.texto)),
              if (_votacion.totalVotantes > 0)
                Text('${op.totalVotos}',
                    style: TextStyle(color: cs.outline, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEscala(ColorScheme cs) {
    final max = _votacion.escalaMax ?? 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selecciona un valor del 1 al $max',
            style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: List.generate(max, (i) {
            final val = i + 1;
            return ChoiceChip(
              label: Text('$val'),
              selected: _valorEscala == val,
              onSelected: _modoLectura ? null : (_) => setState(() => _valorEscala = val),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTextoLibre() {
    return TextFormField(
      controller: _textoCtrl,
      readOnly: _modoLectura,
      decoration: const InputDecoration(
        labelText: 'Tu respuesta',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 5,
      maxLength: 2000,
    );
  }

  Future<void> _votar() async {
    final body = <String, dynamic>{};

    switch (_votacion.tipoVotacion) {
      case 'OPCION_UNICA':
        if (_opcionSeleccionada == null) {
          _mostrarError('Selecciona una opción');
          return;
        }
        body['opcionIds'] = [_opcionSeleccionada];
        break;
      case 'OPCION_MULTIPLE':
        if (_opcionesSeleccionadas.isEmpty) {
          _mostrarError('Selecciona al menos una opción');
          return;
        }
        body['opcionIds'] = _opcionesSeleccionadas.toList();
        break;
      case 'ESCALA_NUMERICA':
        if (_valorEscala == null) {
          _mostrarError('Selecciona un valor');
          return;
        }
        body['valorNumerico'] = _valorEscala;
        break;
      case 'TEXTO_LIBRE':
        if (_textoCtrl.text.trim().isEmpty) {
          _mostrarError('Escribe tu respuesta');
          return;
        }
        body['respuestaTexto'] = _textoCtrl.text.trim();
        break;
    }

    setState(() => _enviando = true);
    try {
      final resultado = await context.read<VotacionProvider>().votar(_votacion.id, body);
      setState(() {
        _votacion = resultado;
        _modoLectura = !resultado.permiteCambiarVoto;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Voto registrado con éxito!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _mostrarError(e.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}
