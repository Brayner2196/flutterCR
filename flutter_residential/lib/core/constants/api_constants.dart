
class ApiConstants {

  //static const String baseUrl = AppEnv.baseUrl;
  static const String baseUrl = 'https://myproyectcrdev.up.railway.app';


  // Auth
  static const String login = '/auth/login';
  static const String seleccionarTenant = '/auth/login/seleccionar';
  static const String registro = '/auth/registro';
  static const String refresh = '/auth/refresh';
  
  // Usuarios
  static const String usuarios = '/api/usuarios';
  static const String usuariosPendientes = '/api/usuarios/pendientes';

  // Tenants
  static const String tenants = '/api/tenants';
  static const String tenantsReprovisionar = '/api/tenants/reprovisionar';

  // Cartera — configuración de estados (admin)
  static const String carteraEstados = '/api/admin/cartera/estados';
  static const String carteraSeed = '/api/admin/cartera/seed';
  // Estado de cartera vigente de todas las propiedades (badges)
  static const String carteraEstadosVigentes = '/api/admin/propiedades/estados-cartera';
  // Gestión de cobranza — avisos a morosos
  static String carteraNotificar(int propiedadId) =>
      '/api/admin/propiedades/$propiedadId/cartera/notificar';
  static const String carteraNotificarMasivo =
      '/api/admin/propiedades/cartera/notificar-masivo';

  // Propiedades — público (registro)
  static const String authTiposPropiedad = '/auth/tiposPropiedad';
  // Valores permitidos por tipo (público, para dropdowns del registro)
  static String authValoresPropiedad(int tipoId) =>
      '/auth/tiposPropiedad/$tipoId/valores';

  // Propiedades — admin
  static const String tiposPropiedad = '/api/tipos-propiedad';
  static const String propiedades = '/api/propiedades';

  // Valores permitidos por tipo — admin (catálogo + dropdowns)
  static String valoresPorTipo(int tipoId) =>
      '/api/tipos-propiedad/$tipoId/valores';
  static String valoresTodosPorTipo(int tipoId) =>
      '/api/tipos-propiedad/$tipoId/valores/todos';
  static String valorPropiedad(int id) => '/api/valores-propiedad/$id';

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
  static const String historialCobrosPageable = '/api/residente/cobros/historial-paginado';
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
  static String tenantPasarelaToggle(int tenantId, int pasarelaId) => '/api/tenants/$tenantId/pasarelas/$pasarelaId/toggle';
  static String tenantPasarelaEliminar(int tenantId, int pasarelaId) => '/api/tenants/$tenantId/pasarelas/$pasarelaId';

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
  static String historialPqr(int id) => '/api/residente/pqrs/$id/historial';

  // Reservas — admin
  static const String adminReservas = '/api/admin/reservas';
  static const String adminZonasComunes = '/api/admin/zonas-comunes';
  static String aprobarReserva(int id) => '/api/admin/reservas/$id/aprobar';
  static String rechazarReserva(int id) => '/api/admin/reservas/$id/rechazar';
  static String actualizarZona(int id) => '/api/admin/zonas-comunes/$id';
  static String suspenderZona(int id) => '/api/admin/zonas-comunes/$id/suspender';
  static String reactivarZona(int id) => '/api/admin/zonas-comunes/$id/reactivar';
  static String excepcionesZona(int id) => '/api/admin/zonas-comunes/$id/excepciones';
  static String eliminarExcepcionZona(int zonaId, int excId) => '/api/admin/zonas-comunes/$zonaId/excepciones/$excId';

  // Reservas — residente
  static const String residenteZonasComunes = '/api/residente/zonas-comunes';
  static const String residenteReservas = '/api/residente/reservas';
  static const String misReservas = '/api/residente/reservas/me';
  static String cancelarReserva(int id) => '/api/residente/reservas/$id/cancelar';
  static String disponibilidadZona(int id, String fecha) =>
      '/api/residente/zonas-comunes/$id/disponibilidad?fecha=$fecha';

  // Anuncios — admin
  static const String adminAnuncios = '/api/admin/anuncios';
  static String estadoAnuncio(int id) => '/api/admin/anuncios/$id/estado';
  static String vistasAnuncio(int id) => '/api/admin/anuncios/$id/vistas';

  // Anuncios — residente
  static const String residenteAnuncios = '/api/residente/anuncios';
  static String marcarAnuncioVisto(int id) => '/api/residente/anuncios/$id/visto';

  // Documentos de interés general — admin
  static const String adminDocumentos = '/api/admin/documentos';
  static String adminDocumento(int id) => '/api/admin/documentos/$id';
  static String adminDocumentoEstado(int id) => '/api/admin/documentos/$id/estado';
  static String adminDocumentoArchivos(int id) => '/api/admin/documentos/$id/archivos';
  static String adminDocumentoArchivo(int id, int archivoId) =>
      '/api/admin/documentos/$id/archivos/$archivoId';
  static String adminDocumentoArchivoUrl(int id, int archivoId) =>
      '/api/admin/documentos/$id/archivos/$archivoId/url';

  // Documentos de interés general — residente
  static const String residenteDocumentos = '/api/residente/documentos';
  static String residenteDocumento(int id) => '/api/residente/documentos/$id';
  static String residenteDocumentoArchivoUrl(int id, int archivoId) =>
      '/api/residente/documentos/$id/archivos/$archivoId/url';

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

  // Plan de Pago — admin
  static const String adminPlanPagoConfig = '/api/admin/planes-pago/configuracion';
  static const String adminPlanesPago = '/api/admin/planes-pago';
  static String adminPlanPago(int id) => '/api/admin/planes-pago/$id';
  static String adminDecidirPlan(int id) => '/api/admin/planes-pago/$id/decidir';
  static String adminCancelarPlan(int id) => '/api/admin/planes-pago/$id/cancelar';
  static String adminMarcarCuotaPagada(int planId, int cuotaId) =>
      '/api/admin/planes-pago/$planId/cuotas/$cuotaId/pagar';

  // Plan de Pago — residente
  static const String residentePlanPagoConfig = '/api/residente/planes-pago/configuracion';
  static const String residentePlanesPago = '/api/residente/planes-pago';
  static const String residentePlanActivo = '/api/residente/planes-pago/activo';

  // Transparencia Presupuesto — admin
  static const String adminPresupuestos = '/api/admin/presupuestos';
  static String adminPresupuesto(int id) => '/api/admin/presupuestos/$id';
  static String adminPresupuestoToggleActivo(int id) => '/api/admin/presupuestos/$id/activo';
  static String adminPresupuestoGastos(int id) => '/api/admin/presupuestos/$id/gastos';
  static String adminEliminarGasto(int presupuestoId, int gastoId) =>
      '/api/admin/presupuestos/$presupuestoId/gastos/$gastoId';

  // Transparencia Presupuesto — residente
  static const String residentePresupuestos = '/api/residente/presupuestos';
  static const String residentePresupuestoActivo = '/api/residente/presupuestos/activo';

  // Parqueaderos — admin
  static const String adminParqueaderosConfig  = '/api/admin/parqueaderos/configuracion';
  static const String adminParqueaderos        = '/api/admin/parqueaderos';
  static const String adminParqueaderosBulk    = '/api/admin/parqueaderos/bulk';
  static const String adminVehiculos           = '/api/admin/parqueaderos/vehiculos';
  static String adminParqueaderoAsignarPropiedad(int id) => '/api/admin/parqueaderos/$id/propiedad';
  static String adminParqueaderoEliminar(int id)          => '/api/admin/parqueaderos/$id';
  static String adminVehiculoAprobar(int id)              => '/api/admin/parqueaderos/vehiculos/$id/aprobar';
  static String adminVehiculoRechazar(int id)             => '/api/admin/parqueaderos/vehiculos/$id/rechazar';

  // Parqueaderos — residente
  static const String residenteVehiculos       = '/api/residente/parqueaderos/vehiculos';
  static const String residenteMisParqueaderos = '/api/residente/parqueaderos/mis-parqueaderos';
  static String residenteVehiculoEliminar(int id)                => '/api/residente/parqueaderos/vehiculos/$id';
  static String residenteParqueaderoCambiarVehiculo(int id)      => '/api/residente/parqueaderos/$id/vehiculo';

  // Consejo comunal — directorio público + vista consejero
  static const String consejoMiembros = '/api/consejo/miembros';
  static String consejoPqrs([String? estado]) =>
      estado != null ? '/api/consejo/pqrs?estado=$estado' : '/api/consejo/pqrs';

  // Admin consejo — gestión de miembros (solo TENANT_ADMIN)
  static const String adminConsejo          = '/api/admin/consejo';
  static const String adminConsejoHistorial = '/api/admin/consejo/historial';
  static String adminConsejoId(int id)      => '/api/admin/consejo/$id';

  // Consejo — actas de reunión por voz (lectura: CONSEJERO+ADMIN, escritura: solo PRESIDENTE)
  static const String consejoActas = '/api/consejo/actas';
  static String consejoActaId(int id)         => '/api/consejo/actas/$id';
  static String consejoActaFinalizar(int id)  => '/api/consejo/actas/$id/finalizar';
  static String consejoActaReintentar(int id) => '/api/consejo/actas/$id/reintentar';

  // Consejo — estadísticas (CONSEJERO + TENANT_ADMIN)
  static String consejoEstadisticas({String? desde, String? hasta}) {
    final params = <String>[];
    if (desde != null) params.add('desde=$desde');
    if (hasta != null) params.add('hasta=$hasta');
    return params.isEmpty
        ? '/api/consejo/estadisticas'
        : '/api/consejo/estadisticas?${params.join('&')}';
  }

  // ── Vigilancia (rol VIGILANTE) ──────────────────────────────────────────
  static String vigilanteAccesoVehicular(String placa) =>
      '/api/vigilante/acceso-vehicular?placa=$placa';
  static const String vigilanteAccesoPeatonal   = '/api/vigilante/acceso-peatonal';
  static String vigilanteConsultarVisita(String codigo) =>
      '/api/vigilante/visitas/${Uri.encodeComponent(codigo)}';
  static String vigilanteAprobarVisita(int id) =>
      '/api/vigilante/visitas/$id/aprobar';
  static String vigilanteRechazarVisita(int id) =>
      '/api/vigilante/visitas/$id/rechazar';
  static String vigilantePropiedades({String? buscar, int page = 0, int size = 20}) {
    final params = <String>['page=$page', 'size=$size'];
    if (buscar != null && buscar.isNotEmpty) {
      params.add('buscar=${Uri.encodeQueryComponent(buscar)}');
    }
    return '/api/vigilante/propiedades?${params.join('&')}';
  }
  static const String vigilantePaquetes         = '/api/vigilante/paquetes';
  static const String vigilantePaquetesPendientes = '/api/vigilante/paquetes/pendientes';
  static String vigilantePaquetesPropiedad(int propiedadId) =>
      '/api/vigilante/paquetes/propiedad/$propiedadId';
  static String vigilanteEntregarPaquete(int id) =>
      '/api/vigilante/paquetes/$id/entregar';
  static String vigilanteBitacora({int limite = 50}) =>
      '/api/vigilante/bitacora?limite=$limite';

  // Vigilancia — residente
  static const String residenteVisitas    = '/api/residente/visitas';
  static const String misVisitas          = '/api/residente/visitas/me';
  static String cancelarVisita(int id)    => '/api/residente/visitas/$id/cancelar';
  static const String misPaquetes         = '/api/residente/paquetes/me';

  // Vigilancia — admin (parametrización + reportes)
  static const String adminVigilanciaConfig = '/api/admin/vigilancia/config';
  static String adminVigilanciaBitacora({String? desde, String? hasta}) {
    final params = <String>[];
    if (desde != null) params.add('desde=$desde');
    if (hasta != null) params.add('hasta=$hasta');
    return params.isEmpty
        ? '/api/admin/vigilancia/bitacora'
        : '/api/admin/vigilancia/bitacora?${params.join('&')}';
  }
}