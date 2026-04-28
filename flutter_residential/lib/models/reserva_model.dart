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

class ZonaComunModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final int capacidad;
  final bool activa;

  const ZonaComunModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.capacidad,
    required this.activa,
  });

  factory ZonaComunModel.fromJson(Map<String, dynamic> json) => ZonaComunModel(
        id: (json['id'] as num).toInt(),
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        capacidad: (json['capacidad'] as num? ?? 0).toInt(),
        activa: json['activa'] as bool? ?? true,
      );
}
