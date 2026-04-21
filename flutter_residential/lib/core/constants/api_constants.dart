class ApiConstants {
  /// Base URL for the API
  //static const String baseUrl = 'http://localhost:8080';
  static const String baseUrl = 'http://10.0.2.2:8080'; // Para emulador Android

  // Auth
  static const String login = '/auth/login';
  static const String seleccionarTenant = '/auth/login/seleccionar';
  static const String registro = '/auth/registro';

  // Usuarios
  static const String usuarios = '/api/usuarios';
  static const String usuariosPendientes = '/api/usuarios/pendientes';

  // Tenants
  static const String tenants = '/api/tenants';

  // Propiedades — público (registro)
  static const String authTiposPropiedad = '/auth/tiposPropiedad';

  // Propiedades — admin
  static const String tiposPropiedad = '/api/tipos-propiedad';
  static const String propiedades = '/api/propiedades';

  // Propiedades — residente autenticado
  static const String misPropiedades = '/api/propiedades/mis-propiedades';

  // Propiedades — admin por residente
  static String propiedadesDeUsuario(int id) => '/api/usuarios/$id/propiedades';
  static String propiedadEstado(int id) => '/api/propiedades/$id/estado';
  static String marcarPropiedadPrincipal(int propId, int userId) =>
      '/api/propiedades/$propId/usuarios/$userId/principal';
}
