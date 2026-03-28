class ApiConstants {
  static const String baseUrl = 'http://localhost:8080';
 // static const String baseUrl = 'http://10.0.2.2:8080'; // Para emulador Android

  // Auth
  static const String login = '/auth/login';
  static const String seleccionarTenant = '/auth/login/seleccionar';
  static const String registro = '/auth/registro';

  // Usuarios
  static const String usuarios = '/api/usuarios';
  static const String usuariosPendientes = '/api/usuarios/pendientes';

  // Tenants
  static const String tenants = '/api/tenants';
}
