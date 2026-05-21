class ApiConstants {
  /// Base URL for the API
  //static const String baseUrl = 'http://localhost:8080';
  //static const String baseUrl = 'http://10.0.2.2:8080'; // Para emulador Android
  //static const String baseUrl = 'https://backendcr-production-991c.up.railway.app'; // Para emulador Android
  static const String baseUrl = 'https://cr-dev.up.railway.app'; // Para emulador Android
  

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

  // Mora — admin
  static const String adminMora = '/api/admin/mora';
  static const String adminMoraHistorico = '/api/admin/mora/historico';

  // Pagos — admin
  static const String adminPeriodos = '/api/admin/cobros/periodos';
  static const String adminCobros = '/api/admin/cobros';
  static const String adminCobrosEspeciales = '/api/admin/cobros/especiales';
  static const String adminPagos = '/api/admin/pagos';
  static const String adminCuotas = '/api/admin/cuotas';
  static const String adminCuotasHistorico = '/api/admin/cuotas/historico';
  static String cerrarPeriodo(int id) => '/api/admin/cobros/periodos/$id/cerrar';
  static String generarCobros(int anio, int mes) => '/api/admin/cobros/generar/$anio/$mes';
  static String previewGenerarCobros(int anio, int mes) => '/api/admin/cobros/generar/$anio/$mes/preview';
  static const String proximoPeriodo = '/api/admin/cobros/proximo-periodo';
  static String exonerarCobro(int id) => '/api/admin/cobros/$id/exonerar';
  static String verificarPago(int id) => '/api/admin/pagos/$id/verificar';
  static String rechazarPago(int id) => '/api/admin/pagos/$id/rechazar';
  static String desactivarCuota(int id) => '/api/admin/cuotas/$id/desactivar';
  static String adminCobrosPorUsuario(int id) => '/api/admin/usuarios/$id/cobros';
  static String adminEstadoCuentaUsuario(int id) => '/api/admin/usuarios/$id/estado-cuenta';

  // Pagos — residente
  static const String estadoCuenta = '/api/residente/estado-cuenta';
  static const String misCobros = '/api/residente/cobros';
  static const String historialCobros = '/api/residente/cobros/historial';
  static String miCobro(int id) => '/api/residente/cobros/$id';
  static const String misPagos = '/api/residente/pagos';
  static String movimientosCobro(int id) => '/api/residente/cobros/$id/movimientos';

  // Confirmación de pagos desde WebView (endpoints en PasarelaController)
  static String mpConfirmarPago(String paymentId) => '/api/pago/confirmar/mp/$paymentId';
  static String wompiConfirmarPago(String txId) => '/api/pago/confirmar/wompi/$txId';

  // Pasarelas de pago (multi-pasarela unificado)
  static const String pasarelasDisponibles = '/api/residente/pago/pasarelas';
  static String pagoCheckout(int cobroId) => '/api/residente/pago/checkout/$cobroId';

  // Admin — gestión de pasarelas
  static const String adminPasarelas = '/api/admin/pasarelas';
  static String adminPasarelaToggle(int id) => '/api/admin/pasarelas/$id/toggle';
  static String adminPasarelaEliminar(int id) => '/api/admin/pasarelas/$id';

  // Super Admin — pasarelas por tenant
  static String tenantPasarelas(int tenantId) => '/api/tenants/$tenantId/pasarelas';
  static String tenantPasarelaToggle(int tenantId, int pasarelaId) =>
      '/api/tenants/$tenantId/pasarelas/$pasarelaId/toggle';
  static String tenantPasarelaEliminar(int tenantId, int pasarelaId) =>
      '/api/tenants/$tenantId/pasarelas/$pasarelaId';

  // Abonos — residente
  static const String misAbonos = '/api/residente/abonos';
  static const String simularAbono = '/api/residente/abonos/simular';
  static const String saldoFavor = '/api/residente/saldo-favor';

  // Abonos — admin
  static const String adminAbonos = '/api/admin/abonos';
  static String verificarAbono(int id) => '/api/admin/abonos/$id/verificar';
  static String rechazarAbono(int id) => '/api/admin/abonos/$id/rechazar';

  // Dashboard — admin
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminDashboardPendientes = '/api/admin/dashboard/pendientes';
  static const String adminDashboardRecaudo = '/api/admin/dashboard/recaudo';
  static const String adminDashboardCartera = '/api/admin/dashboard/cartera';
  static const String adminDashboardTendencia = '/api/admin/dashboard/tendencia';
  static const String adminDashboardUnidades = '/api/admin/dashboard/unidades';

  // PQR — admin
  static const String adminPqrs = '/api/admin/pqrs';
  static String responderPqr(int id) => '/api/admin/pqrs/$id/responder';
  static String estadoPqr(int id) => '/api/admin/pqrs/$id/estado';

  // PQR — residente
  static const String residentePqrs = '/api/residente/pqrs';
  static const String misPqrs = '/api/residente/pqrs/me';

  // Reservas — admin
  static const String adminReservas = '/api/admin/reservas';
  static const String adminZonasComunes = '/api/admin/zonas-comunes';
  static String aprobarReserva(int id) => '/api/admin/reservas/$id/aprobar';
  static String rechazarReserva(int id) => '/api/admin/reservas/$id/rechazar';
  static String actualizarZona(int id) => '/api/admin/zonas-comunes/$id';
  static String suspenderZona(int id) => '/api/admin/zonas-comunes/$id/suspender';
  static String reactivarZona(int id) => '/api/admin/zonas-comunes/$id/reactivar';
  static String excepcionesZona(int id) => '/api/admin/zonas-comunes/$id/excepciones';
  static String eliminarExcepcionZona(int zonaId, int excId) =>
      '/api/admin/zonas-comunes/$zonaId/excepciones/$excId';

  // Reservas — residente
  static const String residenteZonasComunes = '/api/residente/zonas-comunes';
  static const String residenteReservas = '/api/residente/reservas';
  static const String misReservas = '/api/residente/reservas/me';
  static String cancelarReserva(int id) => '/api/residente/reservas/$id/cancelar';

  // Anuncios — admin
  static const String adminAnuncios = '/api/admin/anuncios';
  static String estadoAnuncio(int id) => '/api/admin/anuncios/$id/estado';
  static String vistasAnuncio(int id) => '/api/admin/anuncios/$id/vistas';

  // Anuncios — residente
  static const String residenteAnuncios = '/api/residente/anuncios';
  static String marcarAnuncioVisto(int id) => '/api/residente/anuncios/$id/visto';

  // Votaciones — admin
  static const String adminVotaciones = '/api/admin/votaciones';
  static String estadoVotacion(int id) => '/api/admin/votaciones/$id/estado';
  static String resultadosVotacion(int id) => '/api/admin/votaciones/$id/resultados';

  // Votaciones — residente
  static const String residenteVotaciones = '/api/residente/votaciones';
  static String votarEnVotacion(int id) => '/api/residente/votaciones/$id/votar';

  // Marketplace — residente
  static const String marketplace = '/api/residente/marketplace';
  static const String misPublicaciones = '/api/residente/publicaciones/me';
  static const String crearPublicacion = '/api/residente/publicaciones';
  static String actualizarPublicacion(int id) => '/api/residente/publicaciones/$id';
  static String estadoPublicacion(int id) => '/api/residente/publicaciones/$id/estado';
  static String eliminarPublicacion(int id) => '/api/residente/publicaciones/$id';

  // Solicitudes de pedido — residente (comprador)
  static const String crearSolicitud = '/api/residente/solicitudes';
  static const String misSolicitudesEnviadas = '/api/residente/solicitudes/enviadas';
  static const String misSolicitudesRecibidas = '/api/residente/solicitudes/recibidas';
  static String actualizarEstadoSolicitud(int id) => '/api/residente/solicitudes/$id/estado';

  // Inquilinos — propietario
  static const String misInquilinos = '/api/propietario/inquilinos';
  static String eliminarInquilino(int id) => '/api/propietario/inquilinos/$id';
  static String permisosInquilino(int id) => '/api/propietario/inquilinos/$id/permisos';

  // Inquilinos — propio inquilino
  static const String misPermisos = '/api/inquilino/mis-permisos';

  // Notificaciones push (FCM)
  static const String fcmToken = '/api/notificaciones/token';

  // Marketplace — admin
  static const String adminPublicaciones = '/api/admin/publicaciones';
  static String eliminarPublicacionAdmin(int id) => '/api/admin/publicaciones/$id';

  // Configuración — admin
  static const String adminMiConjunto = '/api/admin/mi-conjunto';
  static String activarUsuario(int id) => '/api/usuarios/$id/activar';
  static String desactivarUsuario(int id) => '/api/usuarios/$id/desactivar';
  static String cambiarRolUsuario(int id) => '/api/usuarios/$id/rol';
}
