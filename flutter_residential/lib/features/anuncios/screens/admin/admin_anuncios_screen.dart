import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/anuncio_provider.dart';
import '../../models/anuncio_model.dart';
import 'admin_crear_anuncio_screen.dart';
import 'admin_vistas_anuncio_screen.dart';

class AdminAnunciosScreen extends StatefulWidget {
  const AdminAnunciosScreen({super.key});

  @override
  State<AdminAnunciosScreen> createState() => _AdminAnunciosScreenState();
}

class _AdminAnunciosScreenState extends State<AdminAnunciosScreen> {
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnuncioProvider>().cargarAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<AnuncioProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anuncios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Crear anuncio',
            onPressed: () => _irACrear(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(cs),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Center(child: Text(provider.error!))
                    : provider.anuncios.isEmpty
                        ? const Center(child: Text('No hay anuncios'))
                        : RefreshIndicator(
                            onRefresh: () => provider.cargarAdmin(estado: _filtroEstado),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.anuncios.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) =>
                                  _AnuncioAdminCard(anuncio: provider.anuncios[i]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _irACrear(context),
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('Nuevo anuncio'),
      ),
    );
  }

  Widget _buildFiltros(ColorScheme cs) {
    final estados = [null, 'ACTIVO', 'INACTIVO', 'ARCHIVADO'];
    final labels = ['Todos', 'Activos', 'Inactivos', 'Archivados'];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: estados.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ChoiceChip(
          label: Text(labels[i]),
          selected: _filtroEstado == estados[i],
          onSelected: (_) {
            setState(() => _filtroEstado = estados[i]);
            context.read<AnuncioProvider>().cargarAdmin(estado: estados[i]);
          },
        ),
      ),
    );
  }

  Future<void> _irACrear(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminCrearAnuncioScreen()),
    );
    if (mounted) context.read<AnuncioProvider>().cargarAdmin(estado: _filtroEstado);
  }
}

class _AnuncioAdminCard extends StatelessWidget {
  final AnuncioModel anuncio;
  const _AnuncioAdminCard({required this.anuncio});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.read<AnuncioProvider>();

    Color estadoColor = switch (anuncio.estado) {
      'ACTIVO' => Colors.green,
      'INACTIVO' => Colors.orange,
      _ => Colors.grey,
    };

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminVistasAnuncioScreen(anuncio: anuncio)),
      ),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: estadoColor,
            width: 0.4
          )
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(anuncio.titulo,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(anuncio.estado,
                        style: TextStyle(color: estadoColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(anuncio.contenido,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text('${anuncio.totalVistas} vistas',
                      style: TextStyle(fontSize: 12)),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (v) => _accion(context, v, provider),
                    itemBuilder: (_) => [
                      if (anuncio.estado != 'ACTIVO')
                        const PopupMenuItem(value: 'ACTIVO', child: Text('Activar')),
                      if (anuncio.estado != 'INACTIVO')
                        const PopupMenuItem(value: 'INACTIVO', child: Text('Desactivar')),
                      if (anuncio.estado != 'ARCHIVADO')
                        const PopupMenuItem(value: 'ARCHIVADO', child: Text('Archivar')),
                      const PopupMenuItem(value: 'EDITAR', child: Text('Editar')),
                      const PopupMenuItem(
                          value: 'ELIMINAR',
                          child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _accion(BuildContext context, String accion, AnuncioProvider provider) async {
    if (accion == 'ELIMINAR') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar anuncio'),
          content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar')),
          ],
        ),
      );
      if (ok == true) await provider.eliminar(anuncio.id);
    } else if (accion == 'EDITAR') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminCrearAnuncioScreen(anuncioEditar: anuncio)),
      );
    } else {
      await provider.cambiarEstado(anuncio.id, accion);
    }
  }
}
