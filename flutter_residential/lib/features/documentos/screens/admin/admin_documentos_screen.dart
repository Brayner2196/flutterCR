import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../models/documento_model.dart';
import '../../providers/documento_provider.dart';
import '../../utils/documento_ui.dart';
import 'admin_crear_documento_screen.dart';

/// Listado de documentos de interés general para el administrador.
/// Permite filtrar por categoría y navegar a la gestión/creación.
class AdminDocumentosScreen extends StatefulWidget {
  const AdminDocumentosScreen({super.key});

  @override
  State<AdminDocumentosScreen> createState() => _AdminDocumentosScreenState();
}

class _AdminDocumentosScreenState extends State<AdminDocumentosScreen> {
  String? _categoria;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentoProvider>().cargarAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DocumentoProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Documentos de interés')),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Center(child: Text(provider.error!))
                    : provider.documentos.isEmpty
                        ? const EmptyStateWidget(
                            icono: Icons.folder_outlined,
                            mensaje: 'No hay documentos',
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                provider.cargarAdmin(categoria: _categoria),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: provider.documentos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm + 2),
                              itemBuilder: (_, i) => _DocumentoAdminCard(
                                documento: provider.documentos[i],
                                onAbrir: () => _abrir(provider.documentos[i].id),
                              ),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(null),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo documento'),
      ),
    );
  }

  Widget _buildFiltros() {
    final categorias = <String?>[null, ...DocumentoUi.categorias];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        itemCount: categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final c = categorias[i];
          return ChoiceChip(
            label: Text(c == null ? 'Todas' : DocumentoUi.labelCategoria(c)),
            selected: _categoria == c,
            onSelected: (_) {
              setState(() => _categoria = c);
              context.read<DocumentoProvider>().cargarAdmin(categoria: c);
            },
          );
        },
      ),
    );
  }

  Future<void> _abrir(int? id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AdminCrearDocumentoScreen(documentoId: id)),
    );
    if (!mounted) return;
    context.read<DocumentoProvider>().cargarAdmin(categoria: _categoria);
  }
}

class _DocumentoAdminCard extends StatelessWidget {
  final DocumentoModel documento;
  final VoidCallback onAbrir;
  const _DocumentoAdminCard({required this.documento, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = DocumentoUi.coloresCategoria(documento.categoria);
    final publicado = documento.publicado;

    return Card(
      color: cs.scrim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        onTap: onAbrir,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(DocumentoUi.iconoCategoria(documento.categoria),
                    color: fg, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(documento.titulo,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '${DocumentoUi.labelCategoria(documento.categoria)} · ${documento.totalArchivos} archivo${documento.totalArchivos == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _BadgeEstado(publicado: publicado),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeEstado extends StatelessWidget {
  final bool publicado;
  const _BadgeEstado({required this.publicado});

  @override
  Widget build(BuildContext context) {
    final bg = publicado ? AppColors.bgGreen : AppColors.bgYellow;
    final fg = publicado ? AppColors.green : AppColors.yellow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(
        publicado ? 'Publicado' : 'Borrador',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
