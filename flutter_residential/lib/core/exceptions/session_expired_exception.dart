/// Lanzada cuando el access token expiró y el refresh token también falló.
/// Sirve para distinguir "sesión muerta" de cualquier otro error de API,
/// de modo que el UI nunca intente parsear una respuesta 401 vacía.
class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => 'Tu sesión ha expirado. Por favor inicia sesión nuevamente.';
}
