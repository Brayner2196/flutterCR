/// Excepción centralizada para errores de API.
/// Reemplaza el patrón `Exception(body['message'])` + `replaceFirst('Exception: ')`
/// que estaba duplicado en más de 90 lugares del proyecto.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;

  /// Extrae el mensaje legible de cualquier tipo de error.
  static String extract(dynamic error) {
    if (error is ApiException) return error.message;
    final raw = error.toString();
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }
}
