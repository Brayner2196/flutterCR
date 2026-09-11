/// Una fila del rastro financiero.
///
/// [valoresAntes] y [valoresDespues] llegan como texto JSON crudo: el backend
/// no conoce la forma de cada entidad auditada y la app tampoco necesita
/// conocerla, se pintan como pares clave/valor genéricos.
class RegistroAuditoria {
  final int id;
  final int? usuarioId;
  final String? usuarioEmail;
  final String? usuarioRol;
  final String entidad;
  final int? entidadId;

  /// Etiqueta legible del registro tocado ("Agosto 2026", "Apto 501"), congelada
  /// por el backend al momento del hecho. Se prefiere sobre [entidadId] al pintar
  /// la tarjeta: un id crudo no le dice nada al administrador, y es lo unico que
  /// da contexto en las acciones masivas, donde [entidadId] llega en null.
  final String? valorEntidad;
  final String accion;
  final String? descripcion;
  final String? valoresAntes;
  final String? valoresDespues;
  final String? endpoint;
  final String? ip;

  /// Los intentos fallidos también se guardan. Un contador tratando de
  /// exonerar sin permiso es justo lo que el administrador necesita ver.
  final bool exitoso;
  final String? mensajeError;
  final DateTime? creadoEn;

  const RegistroAuditoria({
    required this.id,
    this.usuarioId,
    this.usuarioEmail,
    this.usuarioRol,
    required this.entidad,
    this.entidadId,
    this.valorEntidad,
    required this.accion,
    this.descripcion,
    this.valoresAntes,
    this.valoresDespues,
    this.endpoint,
    this.ip,
    required this.exitoso,
    this.mensajeError,
    this.creadoEn,
  });

  factory RegistroAuditoria.fromJson(Map<String, dynamic> json) => RegistroAuditoria(
        id: json['id'] ?? 0,
        usuarioId: json['usuarioId'],
        usuarioEmail: json['usuarioEmail'],
        usuarioRol: json['usuarioRol'],
        entidad: json['entidad'] ?? '',
        entidadId: json['entidadId'],
        valorEntidad: json['valorEntidad'],
        accion: json['accion'] ?? '',
        descripcion: json['descripcion'],
        valoresAntes: json['valoresAntes'],
        valoresDespues: json['valoresDespues'],
        endpoint: json['endpoint'],
        ip: json['ip'],
        exitoso: json['exitoso'] != false,
        mensajeError: json['mensajeError'],
        creadoEn: json['creadoEn'] != null
            ? DateTime.tryParse(json['creadoEn'].toString())
            : null,
      );

  /// Verdadero si el registro trae comparativo que valga la pena desplegar.
  bool get tieneDetalle =>
      (valoresAntes?.isNotEmpty ?? false) || (valoresDespues?.isNotEmpty ?? false);

  /// Qué se muestra junto a la entidad: la etiqueta del backend si vino, el id
  /// como respaldo para los registros anteriores al campo, y nada si no hay
  /// ninguno. Vive en el modelo para que ninguna pantalla repita la decisión.
  String get referenciaLegible {
    final valor = valorEntidad;
    if (valor != null && valor.isNotEmpty) return ' $valor';
    if (entidadId != null) return ' #$entidadId';
    return '';
  }

  /// Texto legible de la acción, para no mostrar el identificador del enum.
  String get accionLegible => nombreAccion(accion);

  String get entidadLegible => nombreEntidad(entidad);

  /// Estáticos para que los desplegables de filtros los usen sin tener que
  /// construir un registro falso solo para leer un texto.
  static String nombreAccion(String accion) => switch (accion) {
        'CREAR' => 'Se creó',
        'ACTUALIZAR' => 'Se actualizó',
        'ELIMINAR' => 'Se eliminó',
        'EXONERAR' => 'Se exoneró',
        'VERIFICAR' => 'Se verificó',
        'RECHAZAR' => 'Rechazó',
        'GENERAR' => 'Se generó',
        'CERRAR' => 'Se cerró',
        'CANCELAR' => 'Se canceló',
        'RECALCULAR' => 'Se recalculó',
        'NOTIFICAR' => 'Se notificó',
        'MIGRAR' => 'Se migró',
        'SIMULAR' => 'Se simuló',
        'OTORGAR_PERMISO' => 'Se otorgó permiso',
        'REVOCAR_PERMISO' => 'Se revocó permiso',
        _ => accion,
      };

  static String nombreEntidad(String entidad) => switch (entidad) {
        'COBRO' => 'Cobro',
        'PERIODO_COBRO' => 'Período de cobro',
        'PAGO' => 'Pago',
        'ABONO' => 'Abono',
        'PLAN_PAGO' => 'Plan de pago',
        'CONFIGURACION_CUOTA' => 'Configuración de cuota',
        'CONFIGURACION_MORA' => 'Configuración de mora',
        'ESTADO_CARTERA' => 'Estado de cartera',
        'PASARELA' => 'Pasarela de pago',
        'PRESUPUESTO' => 'Presupuesto',
        'CARTERA_HISTORICA' => 'Cartera histórica',
        'PERMISO_CONTABLE' => 'Permisos contables',
        _ => entidad,
      };
}

/// Filtros de la bandeja. Todos opcionales: un null desactiva esa condición.
class FiltroAuditoria {
  final int? usuarioId;
  final String? entidad;
  final String? accion;
  final bool soloFallidos;
  final DateTime? desde;
  final DateTime? hasta;

  const FiltroAuditoria({
    this.usuarioId,
    this.entidad,
    this.accion,
    this.soloFallidos = false,
    this.desde,
    this.hasta,
  });

  bool get vacio =>
      usuarioId == null &&
      entidad == null &&
      accion == null &&
      !soloFallidos &&
      desde == null &&
      hasta == null;

  FiltroAuditoria copyWith({
    int? usuarioId,
    String? entidad,
    String? accion,
    bool? soloFallidos,
    DateTime? desde,
    DateTime? hasta,
    bool limpiarUsuario = false,
    bool limpiarEntidad = false,
    bool limpiarAccion = false,
    bool limpiarFechas = false,
  }) =>
      FiltroAuditoria(
        usuarioId: limpiarUsuario ? null : (usuarioId ?? this.usuarioId),
        entidad: limpiarEntidad ? null : (entidad ?? this.entidad),
        accion: limpiarAccion ? null : (accion ?? this.accion),
        soloFallidos: soloFallidos ?? this.soloFallidos,
        desde: limpiarFechas ? null : (desde ?? this.desde),
        hasta: limpiarFechas ? null : (hasta ?? this.hasta),
      );

  Map<String, String> aQueryParams() {
    final q = <String, String>{};
    if (usuarioId != null) q['usuarioId'] = '$usuarioId';
    if (entidad != null) q['entidad'] = entidad!;
    if (accion != null) q['accion'] = accion!;
    if (soloFallidos) q['soloFallidos'] = 'true';
    if (desde != null) q['desde'] = desde!.toUtc().toIso8601String();
    if (hasta != null) q['hasta'] = hasta!.toUtc().toIso8601String();
    return q;
  }
}
