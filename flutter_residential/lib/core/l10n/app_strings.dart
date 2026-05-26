/// Strings centralizados de la aplicación.
///
/// Organización:
///   AppStrings.acciones   → botones y acciones UI
///   AppStrings.errores    → mensajes de error genéricos
///   AppStrings.validacion → mensajes de validación de formularios
///   AppStrings.estados    → etiquetas de estado (backend enums)
///   AppStrings.roles      → roles de usuario
///   AppStrings.meses      → nombres de meses
///   AppStrings.dias       → nombres de días de la semana
///   AppStrings.pagos      → métodos y conceptos de pago
///   AppStrings.nav        → etiquetas de navegación
///   AppStrings.ui         → textos generales de UI
///   AppStrings.auth       → pantallas de autenticación
///   AppStrings.pqr        → módulo PQR
///   AppStrings.reservas   → módulo reservas
///   AppStrings.votaciones → módulo votaciones
///   AppStrings.marketplace → módulo marketplace
///
/// Uso:
///   Text(AppStrings.acciones.cancelar)
///   Text(AppStrings.errores.sinConexion)

// ignore_for_file: non_constant_identifier_names

abstract final class AppStrings {
  // ── Acciones (botones) ──────────────────────────────────────────────────
  static const acciones = _Acciones();

  // ── Errores ─────────────────────────────────────────────────────────────
  static const errores = _Errores();

  // ── Validación de formularios ────────────────────────────────────────────
  static const validacion = _Validacion();

  // ── Estados (enums del backend) ──────────────────────────────────────────
  static const estados = _Estados();

  // ── Roles ────────────────────────────────────────────────────────────────
  static const roles = _Roles();

  // ── Meses ────────────────────────────────────────────────────────────────
  static const meses = _Meses();

  // ── Días de la semana ────────────────────────────────────────────────────
  static const dias = _Dias();

  // ── Pagos ────────────────────────────────────────────────────────────────
  static const pagos = _Pagos();

  // ── Navegación ───────────────────────────────────────────────────────────
  static const nav = _Nav();

  // ── UI general ───────────────────────────────────────────────────────────
  static const ui = _Ui();

  // ── Auth ─────────────────────────────────────────────────────────────────
  static const auth = _Auth();

  // ── PQR ──────────────────────────────────────────────────────────────────
  static const pqr = _Pqr();

  // ── Reservas ─────────────────────────────────────────────────────────────
  static const reservas = _Reservas();

  // ── Votaciones ───────────────────────────────────────────────────────────
  static const votaciones = _Votaciones();

  // ── Marketplace ──────────────────────────────────────────────────────────
  static const marketplace = _Marketplace();
}

// ────────────────────────────────────────────────────────────────────────────
// Acciones
// ────────────────────────────────────────────────────────────────────────────
final class _Acciones {
  const _Acciones();

  String get cancelar       => 'Cancelar';
  String get guardar        => 'Guardar';
  String get guardarCambios => 'Guardar cambios';
  String get editar         => 'Editar';
  String get eliminar       => 'Eliminar';
  String get desactivar     => 'Desactivar';
  String get activar        => 'Activar';
  String get rechazar       => 'Rechazar';
  String get aprobar        => 'Aprobar';
  String get reintentar     => 'Reintentar';
  String get agregar        => 'Agregar';
  String get aceptar        => 'Aceptar';
  String get confirmar      => 'Confirmar';
  String get continuar      => 'Continuar';
  String get volver         => 'Volver';
  String get cerrar         => 'Cerrar';
  String get filtrar        => 'Filtrar';
  String get buscar         => 'Buscar';
  String get limpiar        => 'Limpiar';
  String get enviar         => 'Enviar';
  String get ver            => 'Ver';
  String get verDetalle     => 'Ver detalle';
  String get verTodos       => 'Ver todos';
  String get cargarMas      => 'Cargar más';
  String get copiar         => 'Copiar';
  String get compartir      => 'Compartir';
  String get seleccionar    => 'Seleccionar';
  String get cambiar        => 'Cambiar';
  String get pagar          => 'Pagar';
  String get verificar      => 'Verificar';
  String get votar          => 'Votar';
  String get salir          => 'Salir';
  String get cerrarSesion   => 'Cerrar sesión';
  String get ingresar       => 'Ingresar';
  String get registrarse    => 'Registrarse';
}

// ────────────────────────────────────────────────────────────────────────────
// Errores
// ────────────────────────────────────────────────────────────────────────────
final class _Errores {
  const _Errores();

  String get sinConexion        => 'Sin conexión a internet. Verifica tu red.';
  String get servidorTarde      => 'El servidor tardó demasiado. Inténtalo de nuevo.';
  String get errorInesperado    => 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  String get sesionExpirada     => 'Tu sesión expiró. Por favor inicia sesión de nuevo.';
  String get sinPermiso         => 'No tienes permisos para realizar esta acción.';
  String get recursoNoEncontrado => 'El recurso solicitado no existe.';
  String get errorCargandoDatos => 'Error al cargar los datos.';
  String get errorGuardando     => 'Error al guardar los cambios.';
  String get errorEliminando    => 'Error al eliminar.';
  String get campoRequerido     => 'Campo requerido';
  String get errorConexion      => 'Error de conexión con el servidor.';
}

// ────────────────────────────────────────────────────────────────────────────
// Validación
// ────────────────────────────────────────────────────────────────────────────
final class _Validacion {
  const _Validacion();

  String get requerido          => 'Campo requerido';
  String get correoNoValido     => 'Correo no válido';
  String get min3Caracteres     => 'Mínimo 3 caracteres';
  String get min6Caracteres     => 'Mínimo 6 caracteres';
  String get min8Caracteres     => 'Mínimo 8 caracteres';
  String get max100Caracteres   => 'Máximo 100 caracteres';
  String get max500Caracteres   => 'Máximo 500 caracteres';
  String get soloNumeros        => 'Solo se permiten números';
  String get valorPositivo      => 'El valor debe ser mayor a 0';
  String get contrasenasNoCoinciden => 'Las contraseñas no coinciden';
  String get telefonoNoValido   => 'Teléfono no válido';
  String get fechaNoValida      => 'Fecha no válida';

  /// Mínimo de N caracteres dinámico.
  String minCaracteres(int n) => 'Mínimo $n caracteres';

  /// Máximo de N caracteres dinámico.
  String maxCaracteres(int n) => 'Máximo $n caracteres';
}

// ────────────────────────────────────────────────────────────────────────────
// Estados (enums del backend)
// ────────────────────────────────────────────────────────────────────────────
final class _Estados {
  const _Estados();

  // Genéricos
  String get activo        => 'Activo';
  String get inactivo      => 'Inactivo';
  String get pendiente     => 'Pendiente';
  String get aprobado      => 'Aprobado';
  String get rechazado     => 'Rechazado';
  String get cancelado     => 'Cancelado';
  String get cerrado       => 'Cerrado';
  String get enProceso     => 'En proceso';
  String get resuelto      => 'Resuelto';
  String get activa        => 'Activa';
  String get pausada       => 'Pausada';
  String get borrador      => 'Borrador';
  String get todos         => 'Todos';
  String get todas         => 'Todas';
  String get na            => 'N/A';

  // Pagos / cobros
  String get pagado              => 'Pagado';
  String get vencido             => 'Vencido';
  String get parcial             => 'Parcial';
  String get exonerado           => 'Exonerado';
  String get pendienteVerificacion => 'Pend. verificación';
  String get verificado          => 'Verificado';

  // PQR
  String get abierta       => 'Abierta';
  String get mejorando     => 'Mejorando';

  // Reservas
  String get aprobada      => 'Aprobada';
  String get rechazada     => 'Rechazada';

  // Propiedades
  String get ocupado       => 'Ocupado';
  String get vendida       => 'Vendida';
  String get sinDomicilio  => 'Sin domicilio';

  // Votaciones
  String get votar         => 'Votar';

  // Periodicidad
  String get mensual       => 'Mensual';
  String get trimestral    => 'Trimestral';
  String get semestral     => 'Semestral';
  String get anual         => 'Anual';

  // Tipos de cuota
  String get multa         => 'Multa';
  String get sancion       => 'Sanción';
  String get cobroEspecial => 'Cobro especial';
  String get estadoCuenta  => 'Estado de cuenta';
  String get abono         => 'Abono';

  // Tipos de cierre
  String get cierreEspecial    => 'Cierre especial';
  String get aperturaEspecial  => 'Apertura especial';

  // Tipos de encuesta/votación
  String get opcionUnica    => 'Opción única';
  String get opcionMultiple => 'Opción múltiple';
  String get escalaNum      => 'Escala numérica';
  String get textoLibre     => 'Texto libre';
}

// ────────────────────────────────────────────────────────────────────────────
// Roles
// ────────────────────────────────────────────────────────────────────────────
final class _Roles {
  const _Roles();

  String get superAdmin   => 'Super Admin';
  String get tenantAdmin  => 'Administrador';
  String get propietario  => 'Propietario';
  String get inquilino    => 'Inquilino';
  String get vigilante    => 'Vigilante';
  String get portero      => 'Portero';
  String get piscinero    => 'Piscinero';
  String get contador     => 'Contador';
  String get usuario      => 'Usuario';

  /// Convierte el valor del backend al nombre legible.
  String fromBackend(String rol) => switch (rol) {
        'SUPER_ADMIN'           => superAdmin,
        'TENANT_ADMIN'          => tenantAdmin,
        'PROPIETARIO'           => propietario,
        'PROPIETARIO_PENDIENTE' => '$propietario (pendiente)',
        'INQUILINO'             => inquilino,
        'VIGILANTE'             => vigilante,
        'PORTERO'               => portero,
        'PISCINERO'             => piscinero,
        'CONTADOR'              => contador,
        _                       => rol,
      };
}

// ────────────────────────────────────────────────────────────────────────────
// Meses
// ────────────────────────────────────────────────────────────────────────────
final class _Meses {
  const _Meses();

  static const _nombres = [
    '', // índice 0 vacío para usar índice 1-12
    'Enero', 'Febrero', 'Marzo', 'Abril',
    'Mayo', 'Junio', 'Julio', 'Agosto',
    'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static const _abrev = [
    '',
    'Ene', 'Feb', 'Mar', 'Abr',
    'May', 'Jun', 'Jul', 'Ago',
    'Sep', 'Oct', 'Nov', 'Dic',
  ];

  /// Nombre completo por número de mes (1-12).
  String nombre(int mes) => _nombres[mes];

  /// Abreviación 3 letras por número de mes (1-12).
  String abrev(int mes) => _abrev[mes];

  String get enero      => 'Enero';
  String get febrero    => 'Febrero';
  String get marzo      => 'Marzo';
  String get abril      => 'Abril';
  String get mayo       => 'Mayo';
  String get junio      => 'Junio';
  String get julio      => 'Julio';
  String get agosto     => 'Agosto';
  String get septiembre => 'Septiembre';
  String get octubre    => 'Octubre';
  String get noviembre  => 'Noviembre';
  String get diciembre  => 'Diciembre';
}

// ────────────────────────────────────────────────────────────────────────────
// Días de la semana
// ────────────────────────────────────────────────────────────────────────────
final class _Dias {
  const _Dias();

  String get lunes     => 'Lunes';
  String get martes    => 'Martes';
  String get miercoles => 'Miércoles';
  String get jueves    => 'Jueves';
  String get viernes   => 'Viernes';
  String get sabado    => 'Sábado';
  String get domingo   => 'Domingo';

  /// Backend enum → nombre legible.
  String fromBackend(String dia) => switch (dia) {
        'LUNES'     => lunes,
        'MARTES'    => martes,
        'MIERCOLES' => miercoles,
        'JUEVES'    => jueves,
        'VIERNES'   => viernes,
        'SABADO'    => sabado,
        'DOMINGO'   => domingo,
        _           => dia,
      };
}

// ────────────────────────────────────────────────────────────────────────────
// Pagos
// ────────────────────────────────────────────────────────────────────────────
final class _Pagos {
  const _Pagos();

  // Métodos de pago
  String get efectivo      => 'Efectivo';
  String get transferencia => 'Transferencia';
  String get nequi         => 'Nequi';
  String get daviplata     => 'Daviplata';
  String get bancolombia   => 'Bancolombia';
  String get pse           => 'PSE';
  String get tarjeta       => 'Tarjeta';
  String get otro          => 'Otro';

  // Tipos de cobro
  String get cuotaAdministracion => 'Cuota de administración';
  String get cobroEspecial       => 'Cobro especial';
  String get mora                => 'Mora';
  String get muebles             => 'Muebles';
  String get mascotas            => 'Mascotas';
  String get servicios           => 'Servicios';
  String get otros               => 'Otros';

  // UI de pagos
  String get estadoCuenta        => 'Estado de cuenta';
  String get historialPagos      => 'Historial de pagos';
  String get pagarAhora          => 'Pagar ahora';
  String get saldoFavor          => 'Saldo a favor';
  String get totalDeuda          => 'Total deuda';
  String get sinDeuda            => 'Sin deuda pendiente';
  String get verMovimientos      => 'Ver movimientos';
  String get pagarValorDiferente => 'Pagar un valor diferente';
  String get facturable          => 'Facturable';

  /// Backend enum → nombre legible del método de pago.
  String metodoFromBackend(String metodo) => switch (metodo) {
        'EFECTIVO'      => efectivo,
        'TRANSFERENCIA' => transferencia,
        'NEQUI'         => nequi,
        'DAVIPLATA'     => daviplata,
        'BANCOLOMBIA'   => bancolombia,
        'PSE'           => pse,
        'TARJETA'       => tarjeta,
        _               => otro,
      };

  /// Backend enum → nombre legible del tipo de cobro.
  String tipoFromBackend(String tipo) => switch (tipo) {
        'MULTA'          => 'Multa',
        'SANCION'        => 'Sanción',
        'MUEBLES'        => muebles,
        'MASCOTAS'       => mascotas,
        'SERVICIOS'      => servicios,
        'ESTADO_CUENTA'  => estadoCuenta,
        'ABONO'          => 'Abono',
        _                => otros,
      };
}

// ────────────────────────────────────────────────────────────────────────────
// Navegación
// ────────────────────────────────────────────────────────────────────────────
final class _Nav {
  const _Nav();

  String get inicio        => 'Inicio';
  String get pagos         => 'Pagos';
  String get reservas      => 'Reservas';
  String get pqr           => 'PQR';
  String get anuncios      => 'Anuncios';
  String get votaciones    => 'Votaciones';
  String get marketplace   => 'Marketplace';
  String get perfil        => 'Perfil';
  String get configuracion => 'Configuración';
  String get usuarios      => 'Usuarios';
  String get propiedades   => 'Propiedades';
  String get tenants       => 'Conjuntos';
  String get servicios     => 'Servicios';
  String get dashboard     => 'Dashboard';
}

// ────────────────────────────────────────────────────────────────────────────
// UI general
// ────────────────────────────────────────────────────────────────────────────
final class _Ui {
  const _Ui();

  String get cargando        => 'Cargando...';
  String get sinResultados   => 'Sin resultados';
  String get sinDatos        => 'No hay datos para mostrar';
  String get sinRegistros    => 'No hay registros aún';
  String get listVacia       => 'La lista está vacía';
  String get buscando        => 'Buscando...';
  String get procesando      => 'Procesando...';
  String get guardando       => 'Guardando...';
  String get eliminando      => 'Eliminando...';
  String get exito           => '¡Éxito!';
  String get confirmarEliminar => '¿Estás seguro de que deseas eliminar?';
  String get confirmarAccion   => '¿Confirmas esta acción?';
  String get advertencia       => 'Advertencia';
  String get informacion       => 'Información';
  String get cerrarSinGuardar  => '¿Cerrar sin guardar los cambios?';

  // Campos comunes
  String get nombre          => 'Nombre';
  String get nombreCompleto  => 'Nombre completo';
  String get descripcion     => 'Descripción';
  String get correo          => 'Correo electrónico';
  String get contrasena      => 'Contraseña';
  String get telefono        => 'Teléfono';
  String get fecha           => 'Fecha';
  String get hora            => 'Hora';
  String get tipo            => 'Tipo';
  String get estado          => 'Estado';
  String get valor           => 'Valor';
  String get nota            => 'Nota';
  String get observaciones   => 'Observaciones';
  String get unidad          => 'Unidad';
  String get tipoPropiedad   => 'Tipo de propiedad';
  String get tiposPropiedad  => 'Tipos de propiedad';
  String get conjuntoResidencial => 'Conjunto Residencial';

  // Filtros
  String get filtrarPor      => 'Filtrar por';
  String get ordenarPor      => 'Ordenar por';
  String get todos           => 'Todos';
  String get todas           => 'Todas';
}

// ────────────────────────────────────────────────────────────────────────────
// Auth
// ────────────────────────────────────────────────────────────────────────────
final class _Auth {
  const _Auth();

  String get iniciarSesion       => 'Iniciar sesión';
  String get cerrarSesion        => 'Cerrar sesión';
  String get registro            => 'Registro';
  String get correo              => 'Correo electrónico';
  String get contrasena          => 'Contraseña';
  String get olvidoContrasena    => '¿Olvidaste tu contraseña?';
  String get noTieneCuenta       => '¿No tienes cuenta?';
  String get yaTieneCuenta       => '¿Ya tienes cuenta?';
  String get seleccionaConjunto  => 'Selecciona tu conjunto';
  String get codigoConjunto      => 'Código del conjunto';
  String get credencialesInvalidas => 'Credenciales incorrectas';
  String get cuentaInactiva      => 'Tu cuenta está inactiva';
  String get pendienteAprobacion => 'Cuenta pendiente de aprobación';
  String get conjuntoInactivo    => 'El conjunto está inactivo';
}

// ────────────────────────────────────────────────────────────────────────────
// PQR
// ────────────────────────────────────────────────────────────────────────────
final class _Pqr {
  const _Pqr();

  String get titulo           => 'PQR';
  String get nueva            => 'Nueva PQR';
  String get misPqrs          => 'Mis PQRs';
  String get asunto           => 'Asunto';
  String get descripcion      => 'Descripción';
  String get respuesta        => 'Respuesta';
  String get responder        => 'Responder';
  String get categoria        => 'Categoría';
  String get peticion         => 'Petición';
  String get queja            => 'Queja';
  String get reclamo          => 'Reclamo';
  String get sugerencia       => 'Sugerencia';
  String get sinPqrs          => 'No tienes PQRs registradas';
  String get pqrEnviada       => 'PQR enviada exitosamente';
}

// ────────────────────────────────────────────────────────────────────────────
// Reservas
// ────────────────────────────────────────────────────────────────────────────
final class _Reservas {
  const _Reservas();

  String get titulo          => 'Reservas';
  String get nuevaReserva    => 'Nueva reserva';
  String get misReservas     => 'Mis reservas';
  String get zona            => 'Zona común';
  String get zonas           => 'Zonas comunes';
  String get fechaInicio     => 'Fecha de inicio';
  String get fechaFin        => 'Fecha de fin';
  String get horaInicio      => 'Hora de inicio';
  String get horaFin         => 'Hora de fin';
  String get cancelarReserva => 'Cancelar reserva';
  String get sinReservas     => 'No tienes reservas activas';
  String get reservaCreada   => 'Reserva creada exitosamente';
  String get diasPermitidos  => 'Días permitidos';
  String get capacidad       => 'Capacidad';
  String get tarifa          => 'Tarifa';
}

// ────────────────────────────────────────────────────────────────────────────
// Votaciones
// ────────────────────────────────────────────────────────────────────────────
final class _Votaciones {
  const _Votaciones();

  String get titulo          => 'Votaciones';
  String get activas         => 'Votaciones activas';
  String get cerradas        => 'Votaciones cerradas';
  String get pregunta        => 'Pregunta';
  String get opciones        => 'Opciones';
  String get resultados      => 'Resultados';
  String get votoRegistrado  => 'Voto registrado exitosamente';
  String get yaVotaste       => 'Ya participaste en esta votación';
  String get sinVotaciones   => 'No hay votaciones activas';
  String get votos           => 'votos';
}

// ────────────────────────────────────────────────────────────────────────────
// Marketplace
// ────────────────────────────────────────────────────────────────────────────
final class _Marketplace {
  const _Marketplace();

  String get titulo           => 'Marketplace';
  String get nuevaPublicacion => 'Nueva publicación';
  String get misPublicaciones => 'Mis publicaciones';
  String get precio           => 'Precio';
  String get categoria        => 'Categoría';
  String get contactar        => 'Contactar vendedor';
  String get enviarMensaje    => 'Enviar mensaje por la app';
  String get sinPublicaciones => 'No hay publicaciones disponibles';
  String get publicacionActiva => 'Publicación activa';
  String get publicacionVendida => 'Publicación vendida';
}
