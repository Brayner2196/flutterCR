import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/anuncio_model.dart';
import '../../providers/anuncio_provider.dart';

class AdminVistasAnuncioScreen extends StatefulWidget {
  final AnuncioModel anuncio;
  const AdminVistasAnuncioScreen({super.key, required this.anuncio});

  @override
  State<AdminVistasAnuncioScreen> createState() => _AdminVistasAnuncioScreenState();
}

class _AdminVistasAnuncioScreenState extends State<AdminVistasAnuncioScreen> {
  List<AnuncioVistaModel> _vistas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    _vistas = await context.read<AnuncioProvider>().cargarVistas(widget.anuncio.id);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Vistas — ${widget.anuncio.titulo}'),
      ),
      body: _loading ? 
          const Center(child: CircularProgressIndicator())
          : _vistas.isEmpty ? 
              Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_off_outlined, size: 60, color: cs.outline),
                      const SizedBox(height: 12),
                      const Text('Nadie ha visto este anuncio aún'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, color: cs.onPrimaryContainer),
                          const SizedBox(width: 8),
                          Text(
                            '${_vistas.length} residente${_vistas.length != 1 ? 's' : ''} han visto este anuncio',
                            style: TextStyle(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _vistas.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final v = _vistas[i];
                            final fecha = _formatearFecha(v.vistoEn);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: cs.primary,
                                child: Text(
                                  v.residenteNombre.isNotEmpty ? v.residenteNombre[0].toUpperCase() : '?',
                                  style: TextStyle(color: cs.onPrimaryContainer),
                                ),
                              ),
                              title: Text(v.residenteNombre),
                              subtitle: Text('Visto el $fecha'),
                              trailing: Icon(Icons.check_circle_outline, color: Colors.green),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatearFecha(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
