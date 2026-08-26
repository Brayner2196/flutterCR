import 'dart:io';
import 'dart:typed_data';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> guardarYAbrir(Uint8List bytes, String nombre) async {
  final dir = await getTemporaryDirectory();
  final ruta = '${dir.path}/$nombre';
  await File(ruta).writeAsBytes(bytes);
  final resultado = await OpenFilex.open(ruta);
  if (resultado.type != ResultType.done) {
    throw Exception(
        resultado.message.isNotEmpty ? resultado.message : 'No se pudo abrir el archivo');
  }
}

Future<void> guardarYCompartir(Uint8List bytes, String nombre, {String? texto}) async {
  final dir = await getTemporaryDirectory();
  final ruta = '${dir.path}/$nombre';
  final file = File(ruta);
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(ruta)], text: texto);
}

Future<void> borrarArchivo(String ruta) async {
  final f = File(ruta);
  if (await f.exists()) await f.delete();
}