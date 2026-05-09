import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/votacion_model.dart';
import '../../providers/votacion_provider.dart';
import 'admin_crear_votacion_screen.dart';
import 'admin_resultados_votacion_screen.dart';

class AdminVotacionesScreen extends StatefulWidget {
  const AdminVotacionesScreen({super.key});

  @override
  State<AdminVotacionesScreen> createState() => _AdminVotacionesScreenState();
}

class _AdminVotacionesScreenState extends State<AdminVotacionesScreen> {
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VotacionProvider>().cargarAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VotacionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _irACrear(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: provider.loading ? 
                const Center(child: CircularProgressIndicator())
                : provider.error != null ? 
                    Center(child: Text(provider.error!))
                    : provider.votaciones.isEmpty ? 
                        const Center(child: Text('No hay votaciones'))
                        : RefreshIndicator(
                            onRefresh: () => provider.cargarAdmin(estado: _filtroEstado),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.votaciones.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) =>
                                  _VotacionAdminCard(votacion: provider.votaciones[i]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _irACrear(context),
        icon: const Icon(Icons.how_to_vote_outlined),
        label: const Text('Nueva votación'),
      ),
    );
  }

  Widget _buildFiltros() {
    final estados = [null, 'BORRADOR', 'ABIERTA', 'CERRADA', 'ARCHIVADA'];
    final labels = ['Todas', 'Borrador', 'Abiertas', 'Cerradas', 'Archivadas'];
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
            context.read<VotacionProvider>().cargarAdmin(estado: estados[i]);
          },
        ),
      ),
    );
  }

  Future<void> _irACrear(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminCrearVotacionScreen()),
    );
    if (mounted) context.read<VotacionProvider>().cargarAdmin(estado: _filtroEstado);
  }
}

class _VotacionAdminCard extends StatelessWidget {
  final VotacionModel votacion;
  const _VotacionAdminCard({required this.votacion});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.read<VotacionProvider>();

    Color estadoColor = switch (votacion.estado) {
      'ABIERTA' => Colors.green,
      'BORRADOR' => Colors.blue,
      'CERRADA' => Colors.orange,
      _ => Colors.grey,
    };

    String tipoLabel = switch (votacion.tipoVotacion) {
      'OPCION_UNICA' => 'Opción única',
      'OPCION_MULTIPLE' => 'Opción múltiple',
      'ESCALA_NUMERICA' => 'Escala ${votacion.escalaMax != null ? "1-${votacion.escalaMax}" : ""}',
      'TEXTO_LIBRE' => 'Texto libre',
      _ => votacion.tipoVotacion,
    };

    return Card(
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
                  child: Text(votacion.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(votacion.estado,
                      style: TextStyle(color: estadoColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category_outlined, size: 14, color: cs.onSecondary),
                const SizedBox(width: 4),
                Text(tipoLabel, style: TextStyle(fontSize: 12, color: cs.onSecondary)),
                const SizedBox(width: 12),
                Icon(Icons.how_to_vote_outlined, size: 14, color: cs.primary),
                const SizedBox(width: 4),
                Text('${votacion.totalVotantes} votantes',
                    style: TextStyle(fontSize: 12, color: cs.primary)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.bar_chart, size: 16),
                  label: const Text('Resultados'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AdminResultadosVotacionScreen(votacionId: votacion.id)),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _accion(context, v, provider),
                  itemBuilder: (_) => [
                    if (votacion.estado == 'BORRADOR')
                      const PopupMenuItem(value: 'ABIERTA', child: Text('Abrir votación')),
                    if (votacion.estado == 'ABIERTA')
                      const PopupMenuItem(value: 'CERRADA', child: Text('Cerrar votación')),
                    if (votacion.estado != 'ARCHIVADA')
                      const PopupMenuItem(value: 'ARCHIVADA', child: Text('Archivar')),
                    if (votacion.estado == 'BORRADOR')
                      const PopupMenuItem(value: 'EDITAR', child: Text('Editar')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accion(BuildContext context, String accion, VotacionProvider provider) async {
    if (accion == 'EDITAR') {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AdminCrearVotacionScreen(votacionEditar: votacion)),
      );
    } else {
      await provider.cambiarEstado(votacion.id, accion);
    }
  }
}
