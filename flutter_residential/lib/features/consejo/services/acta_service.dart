import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/base_api_service.dart';
import '../models/acta_model.dart';

/// Actas de reunión por voz.
/// Lectura: cualquier consejero. Escritura: solo el PRESIDENTE (validado en backend).
class ActaService {
  /// Sube la grabación y crea el acta (queda PROCESANDO mientras Whisper transcribe).
  static Future<ActaModel> crear({
    required String titulo,
    required String audioPath,
    int? duracionSegundos,
    String? fechaReunionIso,
  }) async {
    final res = await ApiClient.postMultipart(
      ApiConstants.consejoActas,
      fileField: 'audio',
      filePath: audioPath,
      fields: {
        'titulo': titulo,
        if (duracionSegundos != null) 'duracionSegundos': '$duracionSegundos',
        if (fechaReunionIso != null) 'fechaReunion': fechaReunionIso,
      },
      timeout: const Duration(minutes: 10),
    );
    return BaseApiService.parseSingle(
      res,
      ActaModel.fromJson,
      fallbackMsg: 'Error al subir la grabación del acta',
    );
  }

  static Future<List<ActaModel>> listar() async {
    final res = await ApiClient.get(ApiConstants.consejoActas);
    return BaseApiService.parseList(
      res,
      ActaModel.fromJson,
      'Error al obtener las actas',
    );
  }

  static Future<ActaModel> obtener(int id) async {
    final res = await ApiClient.get(ApiConstants.consejoActaId(id));
    return BaseApiService.parseSingle(
      res,
      ActaModel.fromJson,
      fallbackMsg: 'Error al obtener el acta',
    );
  }

  static Future<ActaModel> actualizar(int id,
      {String? titulo, String? contenido}) async {
    final res = await ApiClient.put(ApiConstants.consejoActaId(id), {
      if (titulo != null) 'titulo': titulo,
      if (contenido != null) 'contenido': contenido,
    });
    return BaseApiService.parseSingle(
      res,
      ActaModel.fromJson,
      fallbackMsg: 'Error al guardar el acta',
    );
  }

  static Future<ActaModel> finalizar(int id) async {
    final res = await ApiClient.post(
      ApiConstants.consejoActaFinalizar(id),
      {},
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(
      res,
      ActaModel.fromJson,
      fallbackMsg: 'Error al finalizar el acta',
    );
  }

  static Future<ActaModel> reintentar(int id) async {
    final res = await ApiClient.post(
      ApiConstants.consejoActaReintentar(id),
      {},
      requiresAuth: true,
    );
    return BaseApiService.parseSingle(
      res,
      ActaModel.fromJson,
      fallbackMsg: 'Error al reintentar la transcripción',
    );
  }

  static Future<void> eliminar(int id) async {
    final res = await ApiClient.delete(ApiConstants.consejoActaId(id));
    BaseApiService.assertSuccess(res, fallbackMsg: 'Error al eliminar el acta');
  }
}
