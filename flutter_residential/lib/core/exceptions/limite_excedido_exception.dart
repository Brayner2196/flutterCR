import 'dart:convert';

import 'api_exception.dart';

/// El backend respondió 429 con el código `LIMITE_EXCEDIDO` (rate limiting).
///
/// Extiende [ApiException] para que `BaseProvider.ejecutar` y
/// [ApiException.extract] muestren el mensaje del backend sin código extra
/// ("Demasiados intentos fallidos. Intenta de nuevo en 15 minutos.").
///
/// Es importante que sea un tipo propio y no un 401: un 429 en el refresh
/// NO significa que la sesión murió, solo que hay que esperar. Si se tratara
/// como fallo de refresh, la app cerraría la sesión del usuario.
class LimiteExcedidoException extends ApiException {
  /// Cuánto esperar antes de reintentar (cabecera `Retry-After`). Null si el
  /// backend no la mandó o no se pudo leer.
  final Duration? reintentarEn;

  static const String mensajePorDefecto =
      'Demasiadas solicitudes. Intenta de nuevo en un momento.';

  const LimiteExcedidoException({required super.message, this.reintentarEn})
      : super(statusCode: 429);

  /// Arma la excepción desde el body JSON (`ErrorResponse`) y la cabecera
  /// `Retry-After` en segundos. Tolera body vacío o no-JSON.
  factory LimiteExcedidoException.desdeRespuesta(String body, String? retryAfter) {
    final segundos = int.tryParse(retryAfter?.trim() ?? '');
    var mensaje = mensajePorDefecto;
    try {
      final json = jsonDecode(body);
      final texto = json is Map<String, dynamic> ? json['message'] : null;
      if (texto is String && texto.isNotEmpty) mensaje = texto;
    } catch (_) {
      // Body vacío o no-JSON: se usa el mensaje por defecto.
    }
    return LimiteExcedidoException(
      message: mensaje,
      reintentarEn: segundos != null && segundos > 0 ? Duration(seconds: segundos) : null,
    );
  }
}
