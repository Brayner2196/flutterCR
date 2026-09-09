
enum EstadoCarga {
  /// Nunca se pidió. Default de todo provider recién creado.
  inicial,
  /// Petición en vuelo.
  cargando,
  /// Respondió bien: el dato en memoria es el bueno.
  listo,
  /// Respondió mal o no respondió.
  error;

  /// ¿Ya hay una respuesta (buena o mala)? Es lo que mira el gate de la UI
  /// para saber si puede construir la pantalla definitiva.
  bool get resuelto => this == EstadoCarga.listo || this == EstadoCarga.error;

  /// ¿Sigue sin saberse nada? Complemento de [resuelto], para leer más natural
  /// en los `if`.
  bool get pendiente => !resuelto;
}
