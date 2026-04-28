class PqrModel {
  final int id;
  final String tipo;
  final String asunto;
  final String descripcion;
  final String estado;
  final int residenteId;
  final String residenteNombre;
  final int? propiedadId;
  final String? respuestaAdmin;
  final int? respondidoPor;
  final String? fechaRespuesta;
  final String? creadoEn;

  const PqrModel({
    required this.id,
    required this.tipo,
    required this.asunto,
    required this.descripcion,
    required this.estado,
    required this.residenteId,
    required this.residenteNombre,
    this.propiedadId,
    this.respuestaAdmin,
    this.respondidoPor,
    this.fechaRespuesta,
    this.creadoEn,
  });

  factory PqrModel.fromJson(Map<String, dynamic> json) => PqrModel(
        id: (json['id'] as num).toInt(),
        tipo: json['tipo'] as String,
        asunto: json['asunto'] as String,
        descripcion: json['descripcion'] as String,
        estado: json['estado'] as String,
        residenteId: (json['residenteId'] as num).toInt(),
        residenteNombre: json['residenteNombre'] as String? ?? 'N/A',
        propiedadId: (json['propiedadId'] as num?)?.toInt(),
        respuestaAdmin: json['respuestaAdmin'] as String?,
        respondidoPor: (json['respondidoPor'] as num?)?.toInt(),
        fechaRespuesta: json['fechaRespuesta'] as String?,
        creadoEn: json['creadoEn'] as String?,
      );

  bool get esPendiente => estado == 'PENDIENTE';
  bool get esEnProceso => estado == 'EN_PROCESO';
  bool get esResuelto => estado == 'RESUELTO';
  bool get esCerrado => estado == 'CERRADO';

  String get tipoLegible {
    switch (tipo) {
      case 'PETICION': return 'Petición';
      case 'QUEJA': return 'Queja';
      case 'RECLAMO': return 'Reclamo';
      case 'SUGERENCIA': return 'Sugerencia';
      default: return tipo;
    }
  }

  String get estadoLegible {
    switch (estado) {
      case 'PENDIENTE': return 'Pendiente';
      case 'EN_PROCESO': return 'En proceso';
      case 'RESUELTO': return 'Resuelta';
      case 'CERRADO': return 'Cerrada';
      default: return estado;
    }
  }
}
