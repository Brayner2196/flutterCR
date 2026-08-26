import 'dart:async';
import 'package:web/web.dart' as web;

/// Abre [url] en una pestaña nueva y espera a que el usuario la cierre
/// (manualmente, o sola gracias al window.close() del backend).
/// Al cerrarse, ejecuta [alRegresar]. Corta el chequeo a los 20 min por seguridad.
Future<bool> abrirYEsperarRegreso(String url, Future<void> Function() alRegresar) async {
  final ventana = web.window.open(url, '_blank');
  if (ventana == null) return false;

  var elapsed = Duration.zero;
  const intervalo = Duration(milliseconds: 700);
  const maximo = Duration(minutes: 20);

  late final Timer timer;
  timer = Timer.periodic(intervalo, (_) {
    elapsed += intervalo;
    if (ventana.closed) {
      timer.cancel();
      alRegresar();
    } else if (elapsed >= maximo) {
      timer.cancel();
    }
  });
  return true;
}