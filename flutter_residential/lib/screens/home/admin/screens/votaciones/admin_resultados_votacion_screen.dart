import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../models/votacion_model.dart';
import '../../../../../providers/votacion_provider.dart';

class AdminResultadosVotacionScreen extends StatefulWidget {
  final int votacionId;
  const AdminResultadosVotacionScreen({super.key, required this.votacionId});

  @override
  State<AdminResultadosVotacionScreen> createState() => _AdminResultadosVotacionScreenState();
}

class _AdminResultadosVotacionScreenState extends State<AdminResultadosVotacionScreen> {
  VotacionModel? _votacion;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    _votacion = await context.read<VotacionProvider>().cargarResultados(widget.votacionId);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading? 
          const Center(child: CircularProgressIndicator())
          : _votacion == null ? 
              const Center(child: Text('No se pudo cargar'))
              : _buildContenido(cs),
    );
  }

  Widget _buildContenido(ColorScheme cs) {
    final v = _votacion!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(v.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (v.descripcion != null) ...[
            const SizedBox(height: 4),
            Text(v.descripcion!, style: TextStyle(color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _chip(Icons.how_to_vote_outlined, '${v.totalVotantes} votantes', cs.primary),
              const SizedBox(width: 8),
              _chip(Icons.category_outlined, _tipoLabel(v.tipoVotacion), cs.onSecondary),
            ],
          ),
          const SizedBox(height: 20),

          // Resultados por tipo
          if (v.tipoVotacion == 'OPCION_UNICA' || v.tipoVotacion == 'OPCION_MULTIPLE')
            _ResultadosOpciones(opciones: v.opciones, totalVotantes: v.totalVotantes),

          if (v.tipoVotacion == 'ESCALA_NUMERICA')
            _ResultadosEscala(opciones: v.opciones, escalaMax: v.escalaMax ?? 5),

          if (v.tipoVotacion == 'TEXTO_LIBRE')
            _ResultadosTextoLibre(votantes: v.votantes ?? []),

          // Lista de votantes (admin siempre la ve)
          if (v.votantes != null && v.votantes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Votantes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...v.votantes!.map((vt) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: cs.primary,
                    child: Text(vt.residenteNombre.isNotEmpty ? vt.residenteNombre[0].toUpperCase() : '?',
                        style: TextStyle(color: cs.onPrimaryContainer)),
                  ),
                  title: Text(vt.residenteNombre),
                  subtitle: vt.votadoEn != null
                      ? Text('Votó el ${_formatFecha(vt.votadoEn!)}')
                      : null,
                )),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  String _tipoLabel(String tipo) => switch (tipo) {
        'OPCION_UNICA' => 'Opción única',
        'OPCION_MULTIPLE' => 'Opción múltiple',
        'ESCALA_NUMERICA' => 'Escala numérica',
        'TEXTO_LIBRE' => 'Texto libre',
        _ => tipo,
      };

  String _formatFecha(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _ResultadosOpciones extends StatelessWidget {
  final List<OpcionVotacionModel> opciones;
  final int totalVotantes;
  const _ResultadosOpciones({required this.opciones, required this.totalVotantes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = opciones.fold<int>(0, (sum, o) => sum + o.totalVotos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: opciones.map((op) {
        final pct = total > 0 ? op.totalVotos / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(op.texto)),
                  Text('${op.totalVotos} voto${op.totalVotos != 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 10,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                ),
              ),
              Text('${(pct * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ResultadosEscala extends StatelessWidget {
  final List<OpcionVotacionModel> opciones;
  final int escalaMax;
  const _ResultadosEscala({required this.opciones, required this.escalaMax});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // opciones vacías en escala, mostramos nota
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Escala del 1 al $escalaMax\nVer resultados detallados en la lista de votantes.',
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _ResultadosTextoLibre extends StatelessWidget {
  final List<VotoResidenteModel> votantes;
  const _ResultadosTextoLibre({required this.votantes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final respuestas = votantes.where((v) => v.respuestaTexto != null).toList();
    if (respuestas.isEmpty) {
      return const Text('Sin respuestas aún');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${respuestas.length} respuesta${respuestas.length != 1 ? 's' : ''}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...respuestas.map((v) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.residenteNombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(v.respuestaTexto ?? ''),
                ],
              ),
            )),
      ],
    );
  }
}
