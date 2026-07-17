import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../models/documento_model.dart';
import '../../providers/documento_provider.dart';
import '../../utils/documento_ui.dart';
import 'detalle_documento_screen.dart';

/// Documentos de interés general publicados, visibles para propietarios e inquilinos.
class DocumentosResidenteScreen extends StatefulWidget {
  const DocumentosResidenteScreen({super.key});

  @override
  State<DocumentosResidenteScreen> createState() =>
      _DocumentosResidenteScreenState();
}

class _DocumentosResidenteScreenState extends State<DocumentosResidenteScreen> {
  String? _categoria;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentoProvider>().cargarResidente();
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
                            mensaje: 'No hay documentos disponibles',
                          )
                        : RefreshIndicator(
                            onRefresh: () =>
                                provider.cargarResidente(categoria: _categoria),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: provider.documentos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm + 2),
                              itemBuilder: (_, i) => _DocumentoResidenteCard(
                                documento: provider.documentos[i],
                              ),
                            ),
                          ),
          ),
        ],
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
              context.read<DocumentoProvider>().cargarResidente(categoria: c);
            },
          );
        },
      ),
    );
  }
}

class _DocumentoResidenteCard extends StatelessWidget {
  final DocumentoModel documento;
  const _DocumentoResidenteCard({required this.documento});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = DocumentoUi.coloresCategoria(documento.categoria);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DetalleDocumentoScreen(documento: documento)),
        ),
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
                    if (documento.descripcion != null &&
                        documento.descripcion!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(documento.descripcion!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurface)),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${DocumentoUi.labelCategoria(documento.categoria)} · ${documento.totalArchivos} archivo${documento.totalArchivos == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
