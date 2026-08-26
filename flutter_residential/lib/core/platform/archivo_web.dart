import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> guardarYAbrir(Uint8List bytes, String nombre) async {
  _descargar(bytes, nombre);
}

Future<void> guardarYCompartir(Uint8List bytes, String nombre, {String? texto}) async {
  _descargar(bytes, nombre); // en web no hay "compartir" nativo simple → se descarga
}

Future<void> borrarArchivo(String ruta) async {} // no-op: no hay temp file en web

void _descargar(Uint8List bytes, String nombre) {
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = nombre
    ..click();
  web.URL.revokeObjectURL(url);
}