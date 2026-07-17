import 'package:flutter/material.dart';

import '../../../../core/utils/app_toast.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/documento_model.dart';
import '../../services/documento_service.dart';
import '../../utils/descarga_archivo.dart';
import '../../utils/documento_ui.dart';

/// Detalle de un documento publicado: descripción + lista de archivos descargables.
class DetalleDocumentoScreen extends StatefulWidget {
  final DocumentoModel documento;
  const DetalleDocumentoScreen({super.key, required this.documento});

  @override
  State<DetalleDocumentoScreen> createState() => _DetalleDocumentoScreenState();
}

class _DetalleDocumentoScreenState extends State<DetalleDocumentoScreen> {
  /// id del archivo que se está descargando (para el spinner por fila).
  int? _descargandoId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doc = widget.documento;

    return Scaffold(
      appBar: AppBar(title: Text(DocumentoUi.labelCategoria(doc.categoria))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(doc.titulo,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
          if (doc.descripcion != null && doc.descripcion!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(doc.descripcion!,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Text('Archivos',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: AppSpacing.sm),
          if (doc.archivos.isEmpty)
            Text('Este documento no tiene archivos.',
                style: TextStyle(color: cs.onSurfaceVariant))
          else
            ...doc.archivos.map((a) => _ArchivoDescargableTile(
                  archivo: a,
                  descargando: _descargandoId == a.id,
                  onDescargar: () => _descargar(a),
                )),
        ],
      ),
    );
  }

  Future<void> _descargar(ArchivoDocumentoModel a) async {
    setState(() => _descargandoId = a.id);
    try {
      final res = await DocumentoService.descargarResidente(widget.documento.id, a.id);
      await DescargaArchivo.abrir(res, a.nombreOriginal);
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _descargandoId = null);
    }
  }
}

class _ArchivoDescargableTile extends StatelessWidget {
  final ArchivoDocumentoModel archivo;
  final bool descargando;
  final VoidCallback onDescargar;
  const _ArchivoDescargableTile({
    required this.archivo,
    required this.descargando,
    required this.onDescargar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tamano = DocumentoUi.formatoTamano(archivo.tamanoBytes);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(DocumentoUi.iconoTipo(archivo.tipo), color: cs.primary),
        title: Text(archivo.nombreOriginal,
            maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
        subtitle: tamano.isEmpty ? null : Text(tamano, style: const TextStyle(fontSize: 12)),
        trailing: descargando
            ? const SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.download_outlined),
        onTap: descargando ? null : onDescargar,
      ),
    );
  }
}
