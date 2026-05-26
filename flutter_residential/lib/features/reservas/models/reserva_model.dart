class ReservaModel {
  final int id;
  final int zonaComunId;
  final String zonaComunNombre;
  final int residenteId;
  final String residenteNombre;
  final int? propiedadId;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final String estado;
  final String? observaciones;
  final String? motivoDecision;
  final String? fechaDecision;
  final String? creadoEn;

  const ReservaModel({
    required this.id,
    required this.zonaComunId,
    required this.zonaComunNombre,
    required this.residenteId,
    required this.residenteNombre,
    this.propiedadId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    this.observaciones,
    this.motivoDecision,
    this.fechaDecision,
    this.creadoEn,
  });

  factory ReservaModel.fromJson(Map<String, dynamic> json) => ReservaModel(
        id: (json['id'] as num).toInt(),
        zonaComunId: (json['zonaComunId'] as num).toInt(),
        zonaComunNombre: json['zonaComunNombre'] as String? ?? 'N/A',
        residenteId: (json['residenteId'] as num).toInt(),
        residenteNombre: json['residenteNombre'] as String? ?? 'N/A',
        propiedadId: (json['propiedadId'] as num?)?.toInt(),
        fecha: json['fecha'] as String,
        horaInicio: json['horaInicio'] as String,
        horaFin: json['horaFin'] as String,
        estado: json['estado'] as String,
        observaciones: json['observaciones'] as String?,
        motivoDecision: json['motivoDecision'] as String?,
        fechaDecision: json['fechaDecision'] as String?,
        creadoEn: json['creadoEn'] as String?,
      );

  bool get esPendiente => estado == 'PENDIENTE';
  bool get esAprobada => estado == 'APROBADA';
  bool get esRechazada => estado == 'RECHAZADA';
  bool get esCancelada => estado == 'CANCELADA';

  String get estadoLegible {
    switch (estado) {
      case 'PENDIENTE': return 'Pendiente';
      case 'APROBADA': return 'Aprobada';
      case 'RECHAZADA': return 'Rechazada';
      case 'CANCELADA': return 'Cancelada';
      default: return estado;
    }
  }
}

// ── Horario por grupos ────────────────────────────────────────────────────────

class FranjaHorariaModel {
  final int? id;
  final String horaInicio; // "HH:mm"
  final String horaFin;    // "HH:mm"
  final int orden;

  const FranjaHorariaModel({
    this.id,
    required this.horaInicio,
    required this.horaFin,
    this.orden = 0,
  });

  factory FranjaHorariaModel.fromJson(Map<String, dynamic> json) =>
      FranjaHorariaModel(
        id: (json['id'] as num?)?.toInt(),
        horaInicio: json['horaInicio'] as String,
        horaFin: json['horaFin'] as String,
        orden: (json['orden'] as num? ?? 0).toInt(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'orden': orden,
      };

  /// Duración legible, ej: "8h" o "1h 30m"
  String get duracion {
    final ini = _toMinutes(horaInicio);
    final fin = _toMinutes(horaFin);
    final diff = fin - ini;
    if (diff <= 0) return '';
    final h = diff ~/ 60;
    final m = diff % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static int _toMinutes(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
}

class HorarioGrupoModel {
  final int? id;
  final String etiqueta;
  final String dias; // CSV: "LUNES,MARTES,..."
  final String? nota;
  final int orden;
  final List<FranjaHorariaModel> franjas;

  const HorarioGrupoModel({
    this.id,
    required this.etiqueta,
    required this.dias,
    this.nota,
    this.orden = 0,
    this.franjas = const [],
  });

  factory HorarioGrupoModel.fromJson(Map<String, dynamic> json) =>
      HorarioGrupoModel(
        id: (json['id'] as num?)?.toInt(),
        etiqueta: json['etiqueta'] as String,
        dias: json['dias'] as String,
        nota: json['nota'] as String?,
        orden: (json['orden'] as num? ?? 0).toInt(),
        franjas: (json['franjas'] as List<dynamic>? ?? [])
            .map((f) => FranjaHorariaModel.fromJson(f as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'etiqueta': etiqueta,
        'dias': dias,
        if (nota != null) 'nota': nota,
        'orden': orden,
        'franjas': franjas.map((f) => f.toJson()).toList(),
      };

  List<String> get listaDias =>
      dias.split(',').map((d) => d.trim()).where((d) => d.isNotEmpty).toList();

  String get resumenHorario {
    if (franjas.isEmpty) return 'Sin horario';
    return franjas.map((f) => '${f.horaInicio}–${f.horaFin}').join(' · ');
  }
}

// ── Zona Común ────────────────────────────────────────────────────────────────

class ZonaComunModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? categoria; // SALON, PISCINA, GIMNASIO, BBQ, CANCHA, OTRO
  final int capacidad;
  final bool activa;

  // Modo de uso
  final bool usoExclusivo;
  final int bufferLimpiezaMinutos;

  // Horario legacy
  final String? horaApertura;
  final String? horaCierre;
  final String? diasDisponibles;

  // Horarios por grupos (modelo flexible)
  final List<HorarioGrupoModel> horarioGrupos;

  // Reglas
  final int? duracionMinMinutos;
  final int? duracionMaxMinutos;
  final int? anticipacionMinDias;
  final int? anticipacionMaxDias;
  final int? maxReservasSemana;
  final int? maxReservasMes;
  final int? cancelacionHorasAntes;

  // Aprobación
  final bool requiereAprobacion;
  final String modoAprobacion; // AUTOMATICA, MANUAL, MIXTA

  // Costo
  final bool tieneCosto;
  final String? modoTarifa; // FIJA, POR_HORA, POR_PERSONA
  final double? tarifaMonto;
  final double? depositoMonto;

  // Restricciones
  final bool soloPropietarios;
  final bool sinDeudaPendiente;
  final int? edadMinima;
  final String? soloTorre;

  // Suspensión
  final bool suspendida;
  final String? motivoSuspension;

  const ZonaComunModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.categoria,
    required this.capacidad,
    required this.activa,
    this.usoExclusivo = true,
    this.bufferLimpiezaMinutos = 0,
    this.horaApertura,
    this.horaCierre,
    this.diasDisponibles,
    this.horarioGrupos = const [],
    this.duracionMinMinutos,
    this.duracionMaxMinutos,
    this.anticipacionMinDias,
    this.anticipacionMaxDias,
    this.maxReservasSemana,
    this.maxReservasMes,
    this.cancelacionHorasAntes,
    this.requiereAprobacion = true,
    this.modoAprobacion = 'MANUAL',
    this.tieneCosto = false,
    this.modoTarifa,
    this.tarifaMonto,
    this.depositoMonto,
    this.soloPropietarios = false,
    this.sinDeudaPendiente = false,
    this.edadMinima,
    this.soloTorre,
    this.suspendida = false,
    this.motivoSuspension,
  });

  factory ZonaComunModel.fromJson(Map<String, dynamic> json) => ZonaComunModel(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        categoria: json['categoria'] as String?,
        capacidad: (json['capacidad'] as num? ?? 0).toInt(),
        activa: json['activa'] as bool? ?? true,
        usoExclusivo: json['usoExclusivo'] as bool? ?? true,
        bufferLimpiezaMinutos: (json['bufferLimpiezaMinutos'] as num? ?? 0).toInt(),
        horaApertura: _timeStr(json['horaApertura']),
        horaCierre: _timeStr(json['horaCierre']),
        diasDisponibles: json['diasDisponibles'] as String?,
        horarioGrupos: (json['horarioGrupos'] as List<dynamic>? ?? [])
            .map((g) => HorarioGrupoModel.fromJson(g as Map<String, dynamic>))
            .toList(),
        duracionMinMinutos: (json['duracionMinMinutos'] as num?)?.toInt(),
        duracionMaxMinutos: (json['duracionMaxMinutos'] as num?)?.toInt(),
        anticipacionMinDias: (json['anticipacionMinDias'] as num?)?.toInt(),
        anticipacionMaxDias: (json['anticipacionMaxDias'] as num?)?.toInt(),
        maxReservasSemana: (json['maxReservasSemana'] as num?)?.toInt(),
        maxReservasMes: (json['maxReservasMes'] as num?)?.toInt(),
        cancelacionHorasAntes: (json['cancelacionHorasAntes'] as num?)?.toInt(),
        requiereAprobacion: json['requiereAprobacion'] as bool? ?? true,
        modoAprobacion: json['modoAprobacion'] as String? ?? 'MANUAL',
        tieneCosto: json['tieneCosto'] as bool? ?? false,
        modoTarifa: json['modoTarifa'] as String?,
        tarifaMonto: (json['tarifaMonto'] as num?)?.toDouble(),
        depositoMonto: (json['depositoMonto'] as num?)?.toDouble(),
        soloPropietarios: json['soloPropietarios'] as bool? ?? false,
        sinDeudaPendiente: json['sinDeudaPendiente'] as bool? ?? false,
        edadMinima: (json['edadMinima'] as num?)?.toInt(),
        soloTorre: json['soloTorre'] as String?,
        suspendida: json['suspendida'] as bool? ?? false,
        motivoSuspension: json['motivoSuspension'] as String?,
      );

  static String? _timeStr(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    final p = s.split(':');
    if (p.length >= 2) return '${p[0]}:${p[1]}';
    return s;
  }

  String? get horaAperturaCorta => horaApertura;
  String? get horaCierreCorta => horaCierre;

  List<String> get listaDias =>
      (diasDisponibles?.isNotEmpty == true)
          ? diasDisponibles!.split(',').map((d) => d.trim()).toList()
          : [];

  bool get disponible => activa && !suspendida;

  bool get tieneHorarioGrupos => horarioGrupos.isNotEmpty;

  String get categoriaLegible {
    switch (categoria) {
      case 'SALON':    return 'Salón';
      case 'PISCINA':  return 'Piscina';
      case 'GIMNASIO': return 'Gimnasio';
      case 'BBQ':      return 'BBQ';
      case 'CANCHA':   return 'Cancha';
      default:         return 'Zona común';
    }
  }

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (categoria != null) 'categoria': categoria,
        'capacidad': capacidad,
        'activa': activa,
        'usoExclusivo': usoExclusivo,
        'bufferLimpiezaMinutos': bufferLimpiezaMinutos,
        if (horaApertura != null) 'horaApertura': horaApertura,
        if (horaCierre != null) 'horaCierre': horaCierre,
        if (diasDisponibles != null) 'diasDisponibles': diasDisponibles,
        'horarioGrupos': horarioGrupos.map((g) => g.toJson()).toList(),
        if (duracionMinMinutos != null) 'duracionMinMinutos': duracionMinMinutos,
        if (duracionMaxMinutos != null) 'duracionMaxMinutos': duracionMaxMinutos,
        if (anticipacionMinDias != null) 'anticipacionMinDias': anticipacionMinDias,
        if (anticipacionMaxDias != null) 'anticipacionMaxDias': anticipacionMaxDias,
        if (maxReservasSemana != null) 'maxReservasSemana': maxReservasSemana,
        if (maxReservasMes != null) 'maxReservasMes': maxReservasMes,
        if (cancelacionHorasAntes != null) 'cancelacionHorasAntes': cancelacionHorasAntes,
        'requiereAprobacion': requiereAprobacion,
        'modoAprobacion': modoAprobacion,
        'tieneCosto': tieneCosto,
        if (modoTarifa != null) 'modoTarifa': modoTarifa,
        if (tarifaMonto != null) 'tarifaMonto': tarifaMonto,
        if (depositoMonto != null) 'depositoMonto': depositoMonto,
        'soloPropietarios': soloPropietarios,
        'sinDeudaPendiente': sinDeudaPendiente,
        if (edadMinima != null) 'edadMinima': edadMinima,
        if (soloTorre != null) 'soloTorre': soloTorre,
      };
}

// ── Disponibilidad Zona por Fecha ─────────────────────────────────────────────

class RangoOcupadoModel {
  final String horaInicio;
  final String horaFin;
  const RangoOcupadoModel({required this.horaInicio, required this.horaFin});
  factory RangoOcupadoModel.fromJson(Map<String, dynamic> json) =>
      RangoOcupadoModel(
        horaInicio: json['horaInicio'] as String,
        horaFin: json['horaFin'] as String,
      );
}

class FranjaDisponibilidadModel {
  final String horaInicio;
  final String horaFin;
  final bool libre;
  final int capacidad;
  final int ocupados;
  final List<RangoOcupadoModel> rangosOcupados;

  const FranjaDisponibilidadModel({
    required this.horaInicio,
    required this.horaFin,
    required this.libre,
    required this.capacidad,
    required this.ocupados,
    required this.rangosOcupados,
  });

  factory FranjaDisponibilidadModel.fromJson(Map<String, dynamic> json) =>
      FranjaDisponibilidadModel(
        horaInicio: json['horaInicio'] as String,
        horaFin: json['horaFin'] as String,
        libre: json['libre'] as bool? ?? true,
        capacidad: (json['capacidad'] as num? ?? 0).toInt(),
        ocupados: (json['ocupados'] as num? ?? 0).toInt(),
        rangosOcupados: (json['rangosOcupados'] as List<dynamic>? ?? [])
            .map((r) => RangoOcupadoModel.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  int get minutosInicio {
    final p = horaInicio.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
  int get minutosFin {
    final p = horaFin.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
  bool get esManana => minutosInicio < 12 * 60;
}

class DisponibilidadZonaModel {
  final int zonaId;
  final String fecha;
  final String? grupoEtiqueta;
  final String? grupoDias;
  final String? grupoNota;
  final int bufferLimpiezaMinutos;
  final List<FranjaDisponibilidadModel> franjas;

  const DisponibilidadZonaModel({
    required this.zonaId,
    required this.fecha,
    this.grupoEtiqueta,
    this.grupoDias,
    this.grupoNota,
    required this.bufferLimpiezaMinutos,
    required this.franjas,
  });

  factory DisponibilidadZonaModel.fromJson(Map<String, dynamic> json) =>
      DisponibilidadZonaModel(
        zonaId: (json['zonaId'] as num).toInt(),
        fecha: json['fecha'] as String,
        grupoEtiqueta: json['grupoEtiqueta'] as String?,
        grupoDias: json['grupoDias'] as String?,
        grupoNota: json['grupoNota'] as String?,
        bufferLimpiezaMinutos: (json['bufferLimpiezaMinutos'] as num? ?? 0).toInt(),
        franjas: (json['franjas'] as List<dynamic>? ?? [])
            .map((f) => FranjaDisponibilidadModel.fromJson(f as Map<String, dynamic>))
            .toList(),
      );
}

// ── Excepción de Zona Común ───────────────────────────────────────────────────

class ExcepcionZonaComunModel {
  final int id;
  final int zonaComunId;
  final String fecha;
  final String tipo; // 'CIERRE_ESPECIAL' | 'APERTURA_ESPECIAL'
  final String? horaApertura;
  final String? horaCierre;
  final String? motivo;

  const ExcepcionZonaComunModel({
    required this.id,
    required this.zonaComunId,
    required this.fecha,
    required this.tipo,
    this.horaApertura,
    this.horaCierre,
    this.motivo,
  });

  factory ExcepcionZonaComunModel.fromJson(Map<String, dynamic> json) =>
      ExcepcionZonaComunModel(
        id: (json['id'] as num).toInt(),
        zonaComunId: (json['zonaComunId'] as num).toInt(),
        fecha: json['fecha'] as String,
        tipo: json['tipo'] as String,
        horaApertura: json['horaApertura'] as String?,
        horaCierre: json['horaCierre'] as String?,
        motivo: json['motivo'] as String?,
      );

  bool get esCierre => tipo == 'CIERRE_ESPECIAL';

  String? get horaAperturaCorta => _recortar(horaApertura);
  String? get horaCierreCorta => _recortar(horaCierre);

  String? _recortar(String? t) {
    if (t == null) return null;
    final p = t.split(':');
    return p.length >= 2 ? '${p[0]}:${p[1]}' : t;
  }
}
