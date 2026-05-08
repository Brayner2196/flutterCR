import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/anuncio_model.dart';
import '../../providers/anuncio_provider.dart';

class DetalleAnuncioScreen extends StatefulWidget {
  final AnuncioModel anuncio;
  const DetalleAnuncioScreen({super.key, required this.anuncio});

  @override
  State<DetalleAnuncioScreen> createState() => _DetalleAnuncioScreenState();
}

class _DetalleAnuncioScreenState extends State<DetalleAnuncioScreen> {
  @override
  void initState() {
    super.initState();
    // Marcar como visto al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnuncioProvider>().marcarVisto(widget.anuncio.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Anuncio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.anuncio.imagenUrl != null && widget.anuncio.imagenUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.anuncio.imagenUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              widget.anuncio.titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  widget.anuncio.creadoPorNombre ?? 'Administración',
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today_outlined, size: 14, color: cs.outline),
                const SizedBox(width: 4),
                Text(
                  _formatFecha(widget.anuncio.creadoEn ?? ''),
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              widget.anuncio.contenido,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Text('Anuncio marcado como visto',
                      style: TextStyle(color: Colors.green, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFecha(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}
