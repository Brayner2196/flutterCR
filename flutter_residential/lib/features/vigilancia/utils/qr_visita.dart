import 'dart:convert';

/// Extrae el código de la visita desde el contenido escaneado del QR.
/// Soporta el formato con datos embebidos ("CRV1:" + base64 JSON) y el código
/// simple (o entrada manual) como respaldo.
String extraerCodigoVisita(String raw) {
  final r = raw.trim();
  if (r.startsWith('CRV1:')) {
    try {
      final jsonStr = utf8.decode(base64.decode(r.substring(5)));
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final c = map['c'];
      if (c is String && c.isNotEmpty) return c;
    } catch (_) {
      // payload inválido → usar el texto crudo
    }
  }
  return r;
}
