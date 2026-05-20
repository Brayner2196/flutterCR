import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/anuncio_provider.dart';
import '../../models/anuncio_model.dart';
import '../../utils/fecha_relativa.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/estado_badge.dart';
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
    final maxVistas = provider.anuncios.fold<int>(
      0,
      (m, a) => a.totalVistas > m ? a.totalVistas : m,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anuncios'),
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
                        ? const EmptyStateWidget(
                            icono: Icons.campaign_outlined,
                            mensaje: 'No hay anuncios',
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                provider.cargarAdmin(estado: _filtroEstado),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: provider.anuncios.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm + 2),
                              itemBuilder: (_, i) => _AnuncioAdminCard(
                                anuncio: provider.anuncios[i],
                                maxVistas: maxVistas,
                              ),
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
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        itemCount: estados.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
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
    if (!context.mounted) return;
    context.read<AnuncioProvider>().cargarAdmin(estado: _filtroEstado);
  }
}

class _AnuncioAdminCard extends StatelessWidget {
  final AnuncioModel anuncio;
  final int maxVistas;
  const _AnuncioAdminCard({required this.anuncio, required this.maxVistas});

  String _labelEstado(String e) {
    switch (e) {
      case 'ACTIVO':
        return 'Activo';
      case 'INACTIVO':
        return 'Inactivo';
      case 'ARCHIVADO':
        return 'Archivado';
      default:
        return e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.read<AnuncioProvider>();
    final fraccion =
        maxVistas == 0 ? 0.0 : (anuncio.totalVistas / maxVistas).clamp(0.0, 1.0);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AdminVistasAnuncioScreen(anuncio: anuncio)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      anuncio.titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  EstadoBadge(
                    estado: anuncio.estado,
                    label: _labelEstado(anuncio.estado),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(
                anuncio.contenido,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: fraccion,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${anuncio.totalVistas} vistas',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${fechaRelativa(anuncio.creadoEn)} · ${anuncio.creadoPorNombre ?? 'admin'}',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) => _accion(context, v, provider),
                    itemBuilder: (_) => [
                      if (anuncio.estado != 'ACTIVO')
                        const PopupMenuItem(
                            value: 'ACTIVO', child: Text('Activar')),
                      if (anuncio.estado != 'INACTIVO')
                        const PopupMenuItem(
                            value: 'INACTIVO', child: Text('Desactivar')),
                      if (anuncio.estado != 'ARCHIVADO')
                        const PopupMenuItem(
                            value: 'ARCHIVADO', child: Text('Archivar')),
                      const PopupMenuItem(
                          value: 'EDITAR', child: Text('Editar')),
                      const PopupMenuItem(
                          value: 'ELIMINAR',
                          child: Text('Eliminar',
                              style: TextStyle(color: Colors.red))),
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

  Future<void> _accion(
      BuildContext context, String accion, AnuncioProvider provider) async {
    if (accion == 'ELIMINAR') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar anuncio'),
          content: const Text(
              '¿Estás seguro? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
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
        MaterialPageRoute(
            builder: (_) =>
                AdminCrearAnuncioScreen(anuncioEditar: anuncio)),
      );
    } else {
      await provider.cambiarEstado(anuncio.id, accion);
    }
  }
}
