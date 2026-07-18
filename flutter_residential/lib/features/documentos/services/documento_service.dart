import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/documento_model.dart';

/// Acceso HTTP al módulo Documentos de interés general.
class DocumentoService {
  // ─── Admin ─────────────────────────────────────────────────────────────

  static Future<List<DocumentoModel>> listarAdmin({String? categoria}) async {
    final url = categoria != null
        ? '${ApiConstants.adminDocumentos}?categoria=$categoria'
        : ApiConstants.adminDocumentos;
    final res = await ApiClient.get(url);
    return BaseApiService.parseList(
        res, DocumentoModel.fromJson, 'Error al listar documentos');
  }

  static Future<DocumentoModel> crear(Map<String, dynamic> data) async {
    final res = await ApiClient.post(ApiConstants.adminDocumentos, data,
        requiresAuth: true);
    return BaseApiService.parseSingle(res, DocumentoModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al crear documento');
  }

  static Future<DocumentoModel> actualizar(
      int id, Map<String, dynamic> data) async {
    final res = await ApiClient.put(ApiConstants.adminDocumento(id), data);
    return BaseApiService.parseSingle(res, DocumentoModel.fromJson,
        fallbackMsg: 'Error al actualizar documento');
  }

  static Future<DocumentoModel> cambiarEstado(int id, String estado) async {
    final res =
        await ApiClient.put(ApiConstants.adminDocumentoEstado(id), {'estado': estado});
    return BaseApiService.parseSingle(res, DocumentoModel.fromJson,
        fallbackMsg: 'Error al cambiar estado');
  }

  static Future<void> eliminar(int id) async {
    final res = await ApiClient.delete(ApiConstants.adminDocumento(id));
    BaseApiService.assertSuccess(res,
        successCodes: [200, 204], fallbackMsg: 'Error al eliminar documento');
  }

  /// Sube uno o varios archivos al documento (multipart, campo "archivos").
  static Future<DocumentoModel> subirArchivos(
      int id, List<String> rutas) async {
    final res = await ApiClient.postMultipartFiles(
      ApiConstants.adminDocumentoArchivos(id),
      fileField: 'archivos',
      filePaths: rutas,
    );
    return BaseApiService.parseSingle(res, DocumentoModel.fromJson,
        successCodes: [200, 201], fallbackMsg: 'Error al subir archivos');
  }

  static Future<void> eliminarArchivo(int id, int archivoId) async {
    final res =
        await ApiClient.delete(ApiConstants.adminDocumentoArchivo(id, archivoId));
    BaseApiService.assertSuccess(res,
        successCodes: [200, 204], fallbackMsg: 'Error al eliminar archivo');
  }

  /// Pide al backend una URL firmada (temporal) para descargar el archivo directo de B2.
  static Future<String> urlDescargaAdmin(int id, int archivoId) async {
    final res = await ApiClient.get(ApiConstants.adminDocumentoArchivoUrl(id, archivoId));
    return BaseApiService.parseSingle<String>(
      res,
      (json) => json['url'] as String,
      fallbackMsg: 'No se pudo obtener el enlace de descarga',
    );
  }

  // ─── Residente ─────────────────────────────────────────────────────────

  static Future<List<DocumentoModel>> listarResidente({String? categoria}) async {
    final url = categoria != null
        ? '${ApiConstants.residenteDocumentos}?categoria=$categoria'
        : ApiConstants.residenteDocumentos;
    final res = await ApiClient.get(url);
    return BaseApiService.parseList(
        res, DocumentoModel.fromJson, 'Error al listar documentos');
  }

  /// Pide al backend una URL firmada (temporal) para descargar el archivo directo de B2.
  static Future<String> urlDescargaResidente(int id, int archivoId) async {
    final res = await ApiClient.get(ApiConstants.residenteDocumentoArchivoUrl(id, archivoId));
    return BaseApiService.parseSingle<String>(
      res,
      (json) => json['url'] as String,
      fallbackMsg: 'No se pudo obtener el enlace de descarga',
    );
  }
}
