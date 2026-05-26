import 'dart:convert';
import 'package:http/http.dart' as http;
import '../exceptions/api_exception.dart';

/// Utilidad estática para parsear respuestas HTTP de forma uniforme.
/// Elimina el patrón duplicado de jsonDecode + verificación de statusCode
/// que existía en los 14+ servicios del proyecto.
abstract class BaseApiService {
  /// Parsea una lista de objetos desde la respuesta.
  static List<T> parseList<T>(
    http.Response res,
    T Function(Map<String, dynamic>) fromJson,
    String fallbackMsg,
  ) {
    if (res.statusCode == 200 || res.statusCode == 201) {
      final rawBody = res.body.trim();
      if (rawBody.isEmpty) {
        throw ApiException(message: fallbackMsg, statusCode: res.statusCode);
      }
      try {
        final body = jsonDecode(rawBody) as List;
        return body.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      } on FormatException {
        throw ApiException(message: fallbackMsg, statusCode: res.statusCode);
      }
    }
    throw _buildException(res, fallbackMsg);
  }

  /// Parsea un único objeto desde la respuesta.
  static T parseSingle<T>(
    http.Response res,
    T Function(Map<String, dynamic>) fromJson, {
    List<int> successCodes = const [200, 201],
    required String fallbackMsg,
  }) {
    if (successCodes.contains(res.statusCode)) {
      final rawBody = res.body.trim();
      if (rawBody.isEmpty) {
        throw ApiException(message: fallbackMsg, statusCode: res.statusCode);
      }
      try {
        final body = jsonDecode(rawBody) as Map<String, dynamic>;
        return fromJson(body);
      } on FormatException {
        throw ApiException(message: fallbackMsg, statusCode: res.statusCode);
      }
    }
    throw _buildException(res, fallbackMsg);
  }

  /// Verifica que la respuesta sea exitosa sin parsear cuerpo (ej: DELETE 204).
  static void assertSuccess(
    http.Response res, {
    List<int> successCodes = const [200, 201, 204],
    required String fallbackMsg,
  }) {
    if (!successCodes.contains(res.statusCode)) {
      throw _buildException(res, fallbackMsg);
    }
  }

  static ApiException _buildException(http.Response res, String fallback) {
    final rawBody = res.body.trim();
    if (rawBody.isEmpty) {
      return ApiException(message: fallback, statusCode: res.statusCode);
    }
    try {
      final body = jsonDecode(rawBody);
      final msg = (body is Map)
          ? (body['message'] as String? ?? body['error'] as String? ?? fallback)
          : fallback;
      return ApiException(message: msg, statusCode: res.statusCode);
    } catch (_) {
      return ApiException(message: fallback, statusCode: res.statusCode);
    }
  }
}
