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

// ── Zona Común ────────────────────────────────────────────────────────────────

class ZonaComunModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final int capacidad;
  final bool activa;

  // Horario estándar
  final String? horaApertura; // "HH:mm:ss"
  final String? horaCierre;
  final String? diasDisponibles; // CSV: "LUNES,MARTES,..."

  // Reglas de duración
  final int? duracionMinMinutos;
  final int? duracionMaxMinutos;

  // Reglas de anticipación
  final int? anticipacionMinDias;
  final int? anticipacionMaxDias;

  final bool requiereAprobacion;
  final bool suspendida;
  final String? motivoSuspension;

  const ZonaComunModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.capacidad,
    required this.activa,
    this.horaApertura,
    this.horaCierre,
    this.diasDisponibles,
    this.duracionMinMinutos,
    this.duracionMaxMinutos,
    this.anticipacionMinDias,
    this.anticipacionMaxDias,
    this.requiereAprobacion = true,
    this.suspendida = false,
    this.motivoSuspension,
  });

  factory ZonaComunModel.fromJson(Map<String, dynamic> json) => ZonaComunModel(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        capacidad: (json['capacidad'] as num? ?? 0).toInt(),
        activa: json['activa'] as bool? ?? true,
        horaApertura: json['horaApertura'] as String?,
        horaCierre: json['horaCierre'] as String?,
        diasDisponibles: json['diasDisponibles'] as String?,
        duracionMinMinutos: (json['duracionMinMinutos'] as num?)?.toInt(),
        duracionMaxMinutos: (json['duracionMaxMinutos'] as num?)?.toInt(),
        anticipacionMinDias: (json['anticipacionMinDias'] as num?)?.toInt(),
        anticipacionMaxDias: (json['anticipacionMaxDias'] as num?)?.toInt(),
        requiereAprobacion: json['requiereAprobacion'] as bool? ?? true,
        suspendida: json['suspendida'] as bool? ?? false,
        motivoSuspension: json['motivoSuspension'] as String?,
      );

  /// Hora en formato "HH:mm" (recorta segundos si los tiene)
  String? get horaAperturaCorta => _recortar(horaApertura);
  String? get horaCierreCorta => _recortar(horaCierre);

  String? _recortar(String? t) {
    if (t == null) return null;
    final p = t.split(':');
    if (p.length >= 2) return '${p[0]}:${p[1]}';
    return t;
  }

  List<String> get listaDias =>
      (diasDisponibles?.isNotEmpty == true)
          ? diasDisponibles!.split(',').map((d) => d.trim()).toList()
          : [];

  bool get disponible => activa && !suspendida;
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
