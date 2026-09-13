/// Desenlace de un intento de actualización. Compartido por las dos
/// plataformas para que la UI no tenga que saber en cuál está corriendo.
enum ResultadoActualizacion {
  /// Se descargó y quedó lista: falta reiniciar (móvil) o recargar (web).
  listaParaAplicar,

  /// Se aplicó y la app se está reiniciando/recargando.
  aplicada,

  /// El usuario cerró el diálogo de la tienda. No es un error.
  canceladaPorUsuario,

  /// No hay nada nuevo que instalar todavía.
  sinNovedad,

  /// No se puede actualizar desde aquí: instalación fuera de Play, emulador,
  /// escritorio. La UI ofrece el enlace a la tienda como respaldo.
  noDisponible,

  /// Algo falló durante la descarga o la instalación.
  fallo,
}
