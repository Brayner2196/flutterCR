import '../../../core/providers/base_provider.dart';
import '../models/documento_model.dart';
import '../services/documento_service.dart';

/// Estado del módulo Documentos de interés general (admin y residente).
class DocumentoProvider extends BaseProvider {
  List<DocumentoModel> _documentos = [];

  List<DocumentoModel> get documentos => _documentos;

  // ─── Cargar ────────────────────────────────────────────────────────────

  Future<void> cargarAdmin({String? categoria}) async {
    _documentos = await ejecutar(
          () => DocumentoService.listarAdmin(categoria: categoria),
        ) ??
        [];
  }

  Future<void> cargarResidente({String? categoria}) async {
    _documentos = await ejecutar(
          () => DocumentoService.listarResidente(categoria: categoria),
        ) ??
        [];
  }

  // ─── Acciones admin ──────────────────────────────────────────────────────

  Future<DocumentoModel> crear(Map<String, dynamic> body) async {
    final nuevo = await ejecutar(() => DocumentoService.crear(body));
    if (nuevo == null) throw Exception(error ?? 'Error al crear documento');
    agregarAlInicio(_documentos, nuevo);
    return nuevo;
  }

  Future<DocumentoModel> actualizar(int id, Map<String, dynamic> body) async {
    final actualizado =
        await ejecutar(() => DocumentoService.actualizar(id, body));
    if (actualizado == null) throw Exception(error ?? 'Error al actualizar documento');
    _reemplazarOAgregar(actualizado);
    return actualizado;
  }

  Future<DocumentoModel> cambiarEstado(int id, String estado) async {
    final actualizado =
        await ejecutar(() => DocumentoService.cambiarEstado(id, estado));
    if (actualizado == null) throw Exception(error ?? 'Error al cambiar estado');
    _reemplazarOAgregar(actualizado);
    return actualizado;
  }

  Future<DocumentoModel> subirArchivos(int id, List<String> rutas) async {
    final actualizado =
        await ejecutar(() => DocumentoService.subirArchivos(id, rutas));
    if (actualizado == null) throw Exception(error ?? 'Error al subir archivos');
    _reemplazarOAgregar(actualizado);
    return actualizado;
  }

  Future<void> eliminarArchivo(int id, int archivoId) async {
    await ejecutar(() => DocumentoService.eliminarArchivo(id, archivoId));
  }

  Future<void> eliminarDocumento(int id) async {
    await ejecutar(() => DocumentoService.eliminar(id));
    super.eliminar(_documentos, (d) => d.id == id);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  DocumentoModel? porId(int id) {
    for (final d in _documentos) {
      if (d.id == id) return d;
    }
    return null;
  }

  void _reemplazarOAgregar(DocumentoModel d) {
    final idx = _documentos.indexWhere((x) => x.id == d.id);
    if (idx != -1) {
      _documentos[idx] = d;
    } else {
      _documentos.add(d);
    }
    notifyListeners();
  }
}
