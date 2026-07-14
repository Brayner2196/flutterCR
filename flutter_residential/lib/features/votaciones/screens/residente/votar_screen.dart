import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/votacion_model.dart';
import '../../providers/votacion_provider.dart';

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
  bool _modoLectura = false;

  @override
  void initState() {
    super.initState();
    _votacion = widget.votacion;
    _modoLectura = _votacion.yaVote && !_votacion.permiteCambiarVoto;
    _prePoblarVoto();
  }

  /// Rellena la selección con lo que el usuario ya votó.
  void _prePoblarVoto() {
    if (!_votacion.yaVote) return;

    switch (_votacion.tipoVotacion) {
      case 'OPCION_UNICA':
        if (_votacion.miVotoOpcionIds.isNotEmpty) {
          _opcionSeleccionada = _votacion.miVotoOpcionIds.first;
        }
        break;
      case 'OPCION_MULTIPLE':
        _opcionesSeleccionadas.addAll(_votacion.miVotoOpcionIds);
        break;
      case 'ESCALA_NUMERICA':
        _valorEscala = _votacion.miVotoValorNumerico;
        break;
      case 'TEXTO_LIBRE':
        if (_votacion.miVotoRespuestaTexto != null) {
          _textoCtrl.text = _votacion.miVotoRespuestaTexto!;
        }
        break;
    }
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// OPCION_UNICA con < 5 opciones → grid de cards; si no → radio list.
  bool get _usarGrid =>
      _votacion.tipoVotacion == 'OPCION_UNICA' &&
      _votacion.opciones.length < 5;

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
                style: TextStyle(fontSize: 12, color: cs.primary)),
            const Divider(height: 28),

            // Formulario / resultados según tipo
            if (_votacion.tipoVotacion == 'OPCION_UNICA')
              _usarGrid
                  ? _buildOpcionUnicaGrid(cs)
                  : _buildOpcionUnicaLista(cs),
            if (_votacion.tipoVotacion == 'OPCION_MULTIPLE')
              _buildOpcionMultiple(cs),
            if (_votacion.tipoVotacion == 'ESCALA_NUMERICA')
              _buildEscala(cs),
            if (_votacion.tipoVotacion == 'TEXTO_LIBRE')
              _buildTextoLibre(),

            // Lista de votantes
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
                      : Icon(Icons.how_to_vote_outlined, color: cs.primaryContainer),
                  label: Text(_votacion.yaVote ? 'Cambiar mi voto' : 'Enviar voto', style: TextStyle(color: cs.primaryContainer),),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── OPCION_UNICA: grid de cards (< 5 opciones) ─────────────────────────────

  Widget _buildOpcionUnicaGrid(ColorScheme cs) {
    final opciones = _votacion.opciones;
    final total = opciones.fold<int>(0, (s, o) => s + o.totalVotos);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: opciones.length,
      itemBuilder: (_, i) {
        final op = opciones[i];
        final selected = _opcionSeleccionada == op.id;
        final pct = total > 0 ? op.totalVotos / total : 0.0;
        final mostrarPct = _modoLectura && total > 0 && _votacion.mostrarPorcentajes;
        return _OpcionCard(
          texto: op.texto,
          totalVotos: _votacion.totalVotantes > 0 ? op.totalVotos : null,
          porcentaje: mostrarPct ? pct : null,
          selected: selected,
          enabled: !_modoLectura,
          onTap: _modoLectura
              ? null
              : () => setState(() => _opcionSeleccionada = op.id),
        );
      },
    );
  }

  // ─── OPCION_UNICA: lista de radios (votando) o resultados (modo lectura) ─────

  Widget _buildOpcionUnicaLista(ColorScheme cs) {
    if (_modoLectura) return _buildResultadosOpcionUnicaLista(cs);

    return RadioGroup<int>(
      groupValue: _opcionSeleccionada,
      onChanged: (v) => setState(() => _opcionSeleccionada = v),
      child: Column(
      children: _votacion.opciones.map((op) {
        final selected = _opcionSeleccionada == op.id;
        return RadioListTile<int>(
          value: op.id,
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
      ),
    );
  }

  // ─── Resultados con barras para modo lectura (≥ 5 opciones) ─────────────────

  Widget _buildResultadosOpcionUnicaLista(ColorScheme cs) {
    final opciones = _votacion.opciones;
    final total = opciones.fold<int>(0, (s, o) => s + o.totalVotos);

    // Banner "Tu voto" si aplica
    final opcionVotada = _opcionSeleccionada != null
        ? opciones.where((o) => o.id == _opcionSeleccionada).firstOrNull
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (opcionVotada != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.primary.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.how_to_vote_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tu voto',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        opcionVotada.texto,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        ...opciones.map((op) {
          final esMiVoto = _opcionSeleccionada == op.id;
          final pct = total > 0 ? op.totalVotos / total : 0.0;
          return _ResultadoOpcionRow(
            texto: op.texto,
            totalVotos: op.totalVotos,
            pct: pct,
            esMiVoto: esMiVoto,
            mostrarPorcentaje: _votacion.mostrarPorcentajes,
          );
        }),
      ],
    );
  }

  // ─── OPCION_MULTIPLE ─────────────────────────────────────────────────────────

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

  // ─── ESCALA_NUMERICA ─────────────────────────────────────────────────────────

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

  // ─── TEXTO_LIBRE ─────────────────────────────────────────────────────────────

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

  // ─── Acción de voto ──────────────────────────────────────────────────────────

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
      final provider = context.read<VotacionProvider>();
      final resultado = await provider.votar(_votacion.id, body);
      if (resultado == null) {
        throw Exception(provider.error ?? 'Error al registrar voto');
      }
      setState(() {
        _votacion = resultado;
        _modoLectura = !resultado.permiteCambiarVoto;
        // Re-poblar con el nuevo voto
        _opcionSeleccionada = null;
        _opcionesSeleccionadas.clear();
        _valorEscala = null;
        _prePoblarVoto();
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

// ─── Card de opción única (para el grid) ─────────────────────────────────────

class _OpcionCard extends StatelessWidget {
  final String texto;
  final int? totalVotos;
  final double? porcentaje; // 0.0–1.0, solo en modo lectura
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  const _OpcionCard({
    required this.texto,
    required this.selected,
    required this.enabled,
    this.totalVotos,
    this.porcentaje,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bgColor = selected ? cs.primary : cs.surfaceContainerHighest.withValues(alpha: 0.45);
    final textColor = selected ? cs.primaryContainer : cs.onSurface;
    final subColor = selected ? cs.onPrimary.withValues(alpha: 0.75) : cs.outline;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge "Mi voto" en modo lectura, ícono check en modo selección
            if (selected) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: cs.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 11, color: cs.primaryContainer),
                    const SizedBox(width: 3),
                    Text(
                      enabled ? 'Seleccionada' : 'Mi voto',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (porcentaje != null) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: porcentaje,
                  minHeight: 4,
                  backgroundColor: selected
                      ? cs.onPrimary.withValues(alpha: 0.25)
                      : cs.outlineVariant,
                  color: selected ? cs.onPrimary : cs.primary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${(porcentaje! * 100).toStringAsFixed(0)}%'
                '${totalVotos != null ? '  ·  $totalVotos ${totalVotos == 1 ? 'voto' : 'votos'}' : ''}',
                style: TextStyle(fontSize: 10, color: subColor, fontWeight: FontWeight.w600),
              ),
            ] else if (totalVotos != null) ...[
              const SizedBox(height: 4),
              Text(
                '$totalVotos ${totalVotos == 1 ? 'voto' : 'votos'}',
                style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Fila de resultado con barra de progreso (modo lectura, lista ≥ 5 opciones)

class _ResultadoOpcionRow extends StatelessWidget {
  final String texto;
  final int totalVotos;
  final double pct; // 0.0–1.0
  final bool esMiVoto;
  final bool mostrarPorcentaje;

  const _ResultadoOpcionRow({
    required this.texto,
    required this.totalVotos,
    required this.pct,
    required this.esMiVoto,
    this.mostrarPorcentaje = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: esMiVoto
            ? cs.primaryContainer
            : cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esMiVoto ? cs.primary.withValues(alpha: 0.5) : cs.outlineVariant,
          width: esMiVoto ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  texto,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: esMiVoto ? FontWeight.w700 : FontWeight.w500,
                    color: esMiVoto ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (esMiVoto)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, size: 11, color: cs.primary),
                      const SizedBox(width: 3),
                      Text(
                        'Tu voto',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (mostrarPorcentaje) ...[
                const SizedBox(width: 8),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: esMiVoto ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          if (mostrarPorcentaje) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (_, val, __) => LinearProgressIndicator(
                  value: val,
                  minHeight: 8,
                  backgroundColor: esMiVoto
                      ? cs.primary.withValues(alpha: 0.15)
                      : cs.outlineVariant.withValues(alpha: 0.5),
                  color: esMiVoto ? cs.primary : cs.outline,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$totalVotos ${totalVotos == 1 ? 'voto' : 'votos'}',
              style: TextStyle(
                fontSize: 11,
                color: esMiVoto ? cs.primary.withValues(alpha: 0.8) : cs.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
