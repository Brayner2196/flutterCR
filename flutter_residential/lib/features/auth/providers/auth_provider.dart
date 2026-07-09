import 'dart:async';
import '../../../core/providers/base_provider.dart';
import '../../../core/services/notificacion_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/date_formatter.dart';
import '../models/login_response.dart';
import '../models/multi_tenant_response.dart';
import '../services/auth_service.dart';

enum AuthStatus { inicial, cargando, autenticado, noAutenticado, error }

class AuthProvider extends BaseProvider {
  AuthStatus _status = AuthStatus.inicial;
  String? _token;
  String? _email;
  String? _rol;
  String? _tenantId;
  String? _nombreConjunto;
  String? _nombre;
  String? _timezone;
  bool _esConsejero = false;
  String? _cargoConsejo;

  // Para el flujo multi-tenant: guardamos temporalmente mientras el usuario elige conjunto
  MultiTenantResponse? _multiTenantPendiente;
  String? _passwordTemporal;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Getters públicos (error heredado de BaseProvider)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  AuthStatus get status => _status;
  String? get token => _token;
  String? get email => _email;
  String? get rol => _rol;
  String? get tenantId => _tenantId;
  String? get nombreConjunto => _nombreConjunto;
  String? get nombre => _nombre;
  /// Timezone del tenant activo. Fallback: "America/Bogota".
  String get timezone => _timezone ?? 'America/Bogota';
  MultiTenantResponse? get multiTenantPendiente => _multiTenantPendiente;

  /// Sincroniza la zona horaria del tenant en memoria y en el formateador
  /// global, para que todas las fechas se muestren en la zona del conjunto.
  void _aplicarTimezone(String? tz) {
    _timezone = tz;
    DateFormatter.zonaTenant = tz ?? 'America/Bogota';
  }

  bool get isLoggedIn => _status == AuthStatus.autenticado;
  bool get isAdmin => _rol == 'TENANT_ADMIN';
  bool get isSuperAdmin => _rol == 'SUPER_ADMIN';
  bool get isPropietario => _rol == 'PROPIETARIO';
  bool get isInquilino => _rol == 'INQUILINO';
  /// Rol de portería. PORTERO queda soportado solo por compatibilidad con
  /// usuarios legados; los nuevos se crean siempre como VIGILANTE.
  bool get isVigilante => _rol == 'VIGILANTE' || _rol == 'PORTERO';
  /// Verdadero si el usuario tiene membresía activa en el consejo comunal.
  bool get esConsejero => _esConsejero;
  /// Cargo en el consejo (PRESIDENTE, VICEPRESIDENTE, etc.) o null.
  String? get cargoConsejo => _cargoConsejo;

  /// Verdadero si el usuario tiene acceso al área de residente (PROPIETARIO o INQUILINO)
  bool get isAreaResidente => isPropietario || isInquilino;

  /// Verdadero si el usuario opera el área de vigilancia/portería.
  bool get isAreaVigilancia => isVigilante;

  /// Al iniciar la app: intenta restaurar sesión guardada
  Future<void> cargarSesionGuardada() async {
    _status = AuthStatus.cargando;
    notifyListeners();

    final sesion = await TokenStorage.leerSesion();
    if (sesion['token'] != null) {
      _token = sesion['token'];
      _email = sesion['email'];
      _rol = sesion['rol'];
      _tenantId = sesion['tenantId'];
      _nombreConjunto = sesion['nombreConjunto'];
      _nombre = sesion['nombre'];
      _aplicarTimezone(sesion['timezone']);
      _esConsejero = sesion['esConsejero'] == 'true';
      _cargoConsejo = sesion['cargoConsejo'];
      _status = AuthStatus.autenticado;
    } else {
      _status = AuthStatus.noAutenticado;
    }

    notifyListeners();
  }

  /// Paso 1 del login — puede resultar en autenticado o en selección de tenant
  Future<bool> login(String email, String password) async {
    limpiarError();

    try {
      final resultado = await ejecutar(() => AuthService.login(email, password));

      // ejecutar() atrapa la excepción y devuelve null, guardando el mensaje
      // real (ej: "Credenciales incorrectas") en `error`. Lo propagamos para
      // que la pantalla muestre el SnackBar correcto.
      if (resultado == null) {
        throw Exception(error ?? 'Error al iniciar sesión');
      }

      if (resultado is LoginResponse) {
        await _aplicarSesion(resultado);
        return true; // ir a HomeScreen
      }

      if (resultado is MultiTenantResponse) {
        _multiTenantPendiente = resultado;
        _email = email;
        _passwordTemporal = password;
        _status = AuthStatus.noAutenticado;
        notifyListeners();
        return false; // ir a TenantSelectionScreen
      }

      throw Exception('Respuesta inesperada del servidor');
    } catch (e) {
      _status = AuthStatus.noAutenticado;
      notifyListeners();
      rethrow;
    }
  }

  /// Paso 2 del login multi-tenant — el usuario eligió su conjunto
  Future<void> seleccionarTenant(String tenantId) async {
    limpiarError();

    try {
      final resultado = await ejecutar(() => AuthService.seleccionarTenant(
        email: _email!,
        password: _passwordTemporal!,
        tenantId: tenantId,
      ));
      if (resultado == null) throw Exception(error ?? 'Error al seleccionar tenant');
      _multiTenantPendiente = null;
      _passwordTemporal = null;
      await _aplicarSesion(resultado);
    } catch (e) {
      _status = AuthStatus.noAutenticado;
      notifyListeners();
      rethrow;
    }
  }

  /// Registro de residente pendiente
  Future<String> registro({
    required String nombre,
    required String email,
    required String password,
    required String codigoConjunto,
    String? telefono,
    List<Map<String, dynamic>>? propiedadPath,
  }) async {
    try {
      return await AuthService.registro(
        nombre: nombre,
        email: email,
        password: password,
        codigoConjunto: codigoConjunto,
        telefono: telefono,
        propiedadPath: propiedadPath,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Llamado automáticamente cuando el servidor devuelve 401 (token expirado).
  Future<void> sesionExpirada() async {
    await TokenStorage.borrarSesion();
    _token = null;
    _email = null;
    _rol = null;
    _tenantId = null;
    _nombreConjunto = null;
    _nombre = null;
    _aplicarTimezone(null);
    _esConsejero = false;
    _cargoConsejo = null;
    _multiTenantPendiente = null;
    _passwordTemporal = null;
    setError(null);
    _status = AuthStatus.noAutenticado;
    notifyListeners();
  }

  Future<void> logout() async {
    // Capturar credenciales ANTES de limpiar para pasarlas al HTTP de notificaciones.
    // Esto evita el race condition entre el DELETE y borrarSesion() corriendo en paralelo.
    final tokenActual  = _token;
    final tenantActual = _tenantId;

    // Limpiar estado en memoria y navegar al login INMEDIATAMENTE.
    _token = null;
    _email = null;
    _rol = null;
    _tenantId = null;
    _nombreConjunto = null;
    _nombre = null;
    _aplicarTimezone(null);
    _esConsejero = false;
    _cargoConsejo = null;
    _multiTenantPendiente = null;
    _passwordTemporal = null;
    setError(null);
    _status = AuthStatus.noAutenticado;
    notifyListeners(); // ← El router lleva al login al instante

    // Paralelo real sin race: HTTP usa el token capturado (no lee storage),
    // así borrarSesion() corre al mismo tiempo sin causar 401.
    unawaited(Future.wait([
      NotificacionService().eliminarTokenDelBackend(
        token: tokenActual,
        tenantId: tenantActual,
      ),
      TokenStorage.borrarSesion(),
    ]));
  }

  Future<void> _aplicarSesion(LoginResponse response) async {
    await TokenStorage.guardarSesion(
      token: response.token,
      refreshToken: response.refreshToken,
      email: response.email,
      rol: response.rol,
      tenantId: response.tenantId,
      nombreConjunto: response.nombreConjunto,
      nombre: response.nombre,
      timezone: response.timezone,
      esConsejero: response.esConsejero,
      cargoConsejo: response.cargoConsejo,
    );
    _token = response.token;
    _email = response.email;
    _rol = response.rol;
    _tenantId = response.tenantId;
    _nombreConjunto = response.nombreConjunto;
    _nombre = response.nombre;
    _aplicarTimezone(response.timezone);
    _esConsejero = response.esConsejero;
    _cargoConsejo = response.cargoConsejo;
    _status = AuthStatus.autenticado;
    notifyListeners();

    // Registrar token FCM tras sesión exitosa (no bloquea si falla)
    NotificacionService().registrarTokenEnBackend();
  }
}
