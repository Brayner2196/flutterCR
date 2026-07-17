import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/exceptions/api_exception.dart';

/// Descarga un archivo (respuesta binaria) a un temporal y lo abre con la app
/// nativa del dispositivo. Reutilizable por cualquier módulo que sirva archivos.
class DescargaArchivo {
  DescargaArchivo._();

  static Future<void> abrir(http.Response res, String nombreOriginal) async {
    if (res.statusCode != 200) {
      throw ApiException(
        message: 'No se pudo descargar el archivo',
        statusCode: res.statusCode,
      );
    }

    final nombre = _sanitizar(nombreOriginal);
    final dir = await getTemporaryDirectory();
    final ruta = '${dir.path}/$nombre';
    await File(ruta).writeAsBytes(res.bodyBytes);

    final resultado = await OpenFilex.open(ruta);
    if (resultado.type != ResultType.done) {
      throw Exception(
          resultado.message.isNotEmpty ? resultado.message : 'No se pudo abrir el archivo');
    }
  }

  /// Evita separadores de ruta u otros caracteres problemáticos en el nombre.
  static String _sanitizar(String nombre) {
    final limpio = nombre.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return limpio.isEmpty ? 'archivo' : limpio;
  }
}
