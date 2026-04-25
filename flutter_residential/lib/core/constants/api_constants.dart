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

  // Pagos — admin
  static const String adminPeriodos = '/api/admin/cobros/periodos';
  static const String adminCobros = '/api/admin/cobros';
  static const String adminPagos = '/api/admin/pagos';
  static const String adminCuotas = '/api/admin/cuotas';
  static String cerrarPeriodo(int id) => '/api/admin/cobros/periodos/$id/cerrar';
  static String generarCobros(int anio, int mes) => '/api/admin/cobros/generar/$anio/$mes';
  static String exonerarCobro(int id) => '/api/admin/cobros/$id/exonerar';
  static String verificarPago(int id) => '/api/admin/pagos/$id/verificar';
  static String rechazarPago(int id) => '/api/admin/pagos/$id/rechazar';
  static String desactivarCuota(int id) => '/api/admin/cuotas/$id/desactivar';

  // Pagos — residente
  static const String estadoCuenta = '/api/residente/estado-cuenta';
  static const String misCobros = '/api/residente/cobros';
  static const String historialCobros = '/api/residente/cobros/historial';
  static const String misPagos = '/api/residente/pagos';
}
