/// El backend respondió 426 con el código `VERSION_OBSOLETA`.
///
/// Cubre el caso que el chequeo de arranque no ve: el usuario que dejó la app
/// abierta varios días y nunca la reinició, así que nunca volvió a preguntar
/// por su versión. Se intercepta en un solo punto del `ApiClient`, igual que
/// [ModuloDeshabilitadoException].
class VersionObsoletaException implements Exception {
  final String message;

  const VersionObsoletaException(this.message);

  @override
  String toString() => message;
}
