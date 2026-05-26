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
    // SessionExpiredException tiene su propio toString() limpio
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) return raw.substring(11);
    if (raw.startsWith('FormatException: ')) return 'Error inesperado en la respuesta del servidor';
    return raw;
  }
}
