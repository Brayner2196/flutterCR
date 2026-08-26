import 'package:http/http.dart' as http;

import '../../../core/exceptions/api_exception.dart';
import '../../../core/platform/archivo_io.dart';

/// Descarga un archivo desde una URL firmada (presigned) a un temporal y lo abre
/// con la app nativa del dispositivo. Reutilizable por cualquier módulo que sirva
/// archivos vía enlace temporal de storage.
class DescargaArchivo {
  DescargaArchivo._();

  /// La [url] ya viene autorizada por la firma, por lo que la petición NO lleva
  /// headers de sesión (van directo al bucket, no al backend).
  static Future<void> abrirDesdeUrl(String url, String nombreOriginal) async {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(minutes: 3));
    if (res.statusCode != 200) {
      throw ApiException(message: 'No se pudo descargar el archivo', statusCode: res.statusCode);
    }
    final nombre = _sanitizar(nombreOriginal);
    await guardarYAbrir(res.bodyBytes, nombre);
  }

  static String _sanitizar(String nombre) {
    final limpio = nombre.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return limpio.isEmpty ? 'archivo' : limpio;
  }
}
