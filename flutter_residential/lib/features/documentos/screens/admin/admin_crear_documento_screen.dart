import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/app_toast.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/documento_model.dart';
import '../../providers/documento_provider.dart';
import '../../utils/documento_ui.dart';

/// Crear un documento nuevo o gestionar uno existente (metadata + archivos + publicación).
class AdminCrearDocumentoScreen extends StatefulWidget {
  /// null → modo creación. Con id → modo gestión de un documento existente.
  final int? documentoId;
  const AdminCrearDocumentoScreen({super.key, this.documentoId});

  @override
  State<AdminCrearDocumentoScreen> createState() =>
      _AdminCrearDocumentoScreenState();
}

class _AdminCrearDocumentoScreenState extends State<AdminCrearDocumentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  String _categoria = 'OTROS';

  DocumentoModel? _documento;
  bool _guardando = false;
  bool _subiendo = false;

  static const _extensiones = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'csv',
    'jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov', 'webm',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.documentoId != null) {
      final doc = context.read<DocumentoProvider>().porId(widget.documentoId!);
      if (doc != null) _cargarEnFormulario(doc);
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _cargarEnFormulario(DocumentoModel doc) {
    _documento = doc;
    _tituloCtrl.text = doc.titulo;
    _descripcionCtrl.text = doc.descripcion ?? '';
    _categoria = doc.categoria;
  }

  bool get _esNuevo => _documento == null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esNuevo ? 'Nuevo documento' : 'Editar documento'),
        actions: [
          if (!_esNuevo) _botonPublicar(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildForm(),
          const SizedBox(height: AppSpacing.md),
          if (_esNuevo)
            _hintGuardarPrimero()
          else
            _buildSeccionArchivos(),
        ],
      ),
    );
  }

  // ─── Formulario de metadata ────────────────────────────────────────────────

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _tituloCtrl,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Título'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<String>(
            initialValue: _categoria,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: DocumentoUi.categorias
                .map((c) => DropdownMenuItem(
                    value: c, child: Text(DocumentoUi.labelCategoria(c))))
                .toList(),
            onChanged: (v) => setState(() => _categoria = v ?? 'OTROS'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _descripcionCtrl,
            maxLength: 2000,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Descripción (opcional)', alignLabelWithHint: true),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(_esNuevo ? 'Guardar y continuar' : 'Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final provider = context.read<DocumentoProvider>();
    final body = {
      'titulo': _tituloCtrl.text.trim(),
      'descripcion':
          _descripcionCtrl.text.trim().isEmpty ? null : _descripcionCtrl.text.trim(),
      'categoria': _categoria,
    };
    try {
      final doc = _esNuevo
          ? await provider.crear(body)
          : await provider.actualizar(_documento!.id, body);
      if (!mounted) return;
      setState(() => _documento = doc);
      AppToast.success(context, _esNuevo ? 'Documento creado' : 'Cambios guardados');
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ─── Sección de archivos adjuntos ──────────────────────────────────────────

  Widget _hintGuardarPrimero() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.onSurfaceVariant, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Guarda el documento para poder adjuntar archivos.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionArchivos() {
    final cs = Theme.of(context).colorScheme;
    final archivos = _documento!.archivos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Archivos adjuntos',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const Spacer(),
            Text('${archivos.length}/10',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (archivos.isEmpty)
          Text('Aún no hay archivos adjuntos.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))
        else
          ...archivos.map((a) => _ArchivoTile(
                archivo: a,
                onEliminar: () => _eliminarArchivo(a),
              )),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: (_subiendo || archivos.length >= 10) ? null : _agregarArchivos,
            icon: _subiendo
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.attach_file),
            label: Text(_subiendo ? 'Subiendo...' : 'Agregar archivos'),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PDF, Word, Excel, imágenes y video. Los videos deben ser cortos y de peso moderado.',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
        ),
      ],
    );
  }

  Future<void> _agregarArchivos() async {
    final resultado = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _extensiones,
    );
    if (resultado == null) return;

    final rutas =
        resultado.files.where((f) => f.path != null).map((f) => f.path!).toList();
    if (rutas.isEmpty) return;

    if (_documento!.archivos.length + rutas.length > 10) {
      if (mounted) AppToast.warning(context, 'Máximo 10 archivos por documento');
      return;
    }

    setState(() => _subiendo = true);
    try {
      final doc = await context.read<DocumentoProvider>()
          .subirArchivos(_documento!.id, rutas);
      if (!mounted) return;
      setState(() => _documento = doc);
      AppToast.success(context, 'Archivos subidos');
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<void> _eliminarArchivo(ArchivoDocumentoModel a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content: Text('¿Eliminar "${a.nombreOriginal}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    final provider = context.read<DocumentoProvider>();
    try {
      await provider.eliminarArchivo(_documento!.id, a.id);
      if (!mounted) return;
      setState(() {
        _documento!.archivos.removeWhere((x) => x.id == a.id);
      });
      AppToast.success(context, 'Archivo eliminado');
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    }
  }

  // ─── Publicar / despublicar ────────────────────────────────────────────────

  Widget _botonPublicar() {
    final publicado = _documento?.publicado ?? false;
    return TextButton.icon(
      onPressed: _togglePublicacion,
      icon: Icon(publicado ? Icons.visibility_off_outlined : Icons.publish_outlined),
      label: Text(publicado ? 'Despublicar' : 'Publicar'),
    );
  }

  Future<void> _togglePublicacion() async {
    final doc = _documento!;
    final nuevoEstado = doc.publicado ? 'BORRADOR' : 'PUBLICADO';
    if (nuevoEstado == 'PUBLICADO' && doc.archivos.isEmpty) {
      AppToast.warning(context, 'Agrega al menos un archivo antes de publicar');
      return;
    }
    try {
      final actualizado =
          await context.read<DocumentoProvider>().cambiarEstado(doc.id, nuevoEstado);
      if (!mounted) return;
      setState(() => _documento = actualizado);
      AppToast.success(
          context, nuevoEstado == 'PUBLICADO' ? 'Documento publicado' : 'Pasado a borrador');
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    }
  }
}

class _ArchivoTile extends StatelessWidget {
  final ArchivoDocumentoModel archivo;
  final VoidCallback onEliminar;
  const _ArchivoTile({required this.archivo, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tamano = DocumentoUi.formatoTamano(archivo.tamanoBytes);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(DocumentoUi.iconoTipo(archivo.tipo), color: cs.primary),
      title: Text(archivo.nombreOriginal,
          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
      subtitle: tamano.isEmpty ? null : Text(tamano, style: const TextStyle(fontSize: 12)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: onEliminar,
      ),
    );
  }
}
