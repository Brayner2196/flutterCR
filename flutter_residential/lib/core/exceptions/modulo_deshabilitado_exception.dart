import '../enums/modulo.dart';

/// El backend respondió 403 con el código `MODULO_DESHABILITADO`.
///
/// Se distingue de un 403 por rol para poder mostrar un mensaje entendible
/// ("este conjunto no tiene contratado X") en vez del genérico
/// "Acceso denegado", que hace pensar al usuario que es un problema de
/// permisos suyo.
class ModuloDeshabilitadoException implements Exception {
  final String message;
  final Modulo? modulo;

  ModuloDeshabilitadoException(this.message, {this.modulo});

  @override
  String toString() => message;
}
