/// En móvil esta función no se usa (se abre el WebView nativo directo).
/// Existe solo para que ambos archivos cumplan la misma firma.
Future<bool> abrirYEsperarRegreso(String url, Future<void> Function() alRegresar) async {
  return false;
}